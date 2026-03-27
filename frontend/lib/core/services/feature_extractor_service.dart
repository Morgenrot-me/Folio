// feature_extractor_service.dart
// AI 特征提取服务：ML Kit ImageLabeler（通用中文标签）+ MLKit OCR + 拉普拉斯模糊度
//                  + HSL 主色调/冷暖度 + 截图路径检测
// Phase 1：MobileNetV1 标签管线已替换为 ML Kit ImageLabeler。
//          语义向量（semanticVector）暂写 null，Phase 2 接入 MobileCLIP 后补全。
// Phase 2 预留：_interpreter 字段槽位保留，用于后续接入 MobileCLIP TFLite。

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart'; // Phase 2 MobileCLIP 预留
import '../database/app_database.dart';
import 'package:drift/drift.dart';
import '../constants/mlkit_zh_labels.dart';

/// 多厂商截图路径关键字（小写匹配）
const _screenshotKeywords = [
  'screenshot', 'screen_shot', 'screencap', 'screen-shot',
  'shot_', // MIUI: /Shot_xxx/
  'capture', // 某些 HuaWei
  '截图', '截屏',
  'screenrecord', // 屏幕录制帧
];

class FeatureExtractorService {
  final AppDatabase database;

  late TextRecognizer _textRecognizer;
  late ImageLabeler _imageLabeler;

  /// Phase 2 占位符：MobileCLIP TFLite 解释器（模型文件就绪后启用）
  Interpreter? _mobileclipInterpreter;

  FeatureExtractorService(this.database) {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);
    // Bundled on-device 模式：confidence 阈值 0.65，完全离线
    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.65),
    );
  }

  void dispose() {
    _textRecognizer.close();
    _imageLabeler.close();
    _mobileclipInterpreter?.close();
  }

  /// 核心调度：对单张图片执行全维度特征提取并落库
  Future<void> extractFeaturesForImage(String imageId, String filePath,
      [Uint8List? thumbBytes]) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    // ── 1. OCR 文字检测 ─────────────────────────────────────────────────
    final hasText = await _detectText(file);

    // ── 2. 截图检测（多厂商路径关键字） ────────────────────────────────
    final pathLower = filePath.toLowerCase();
    final isScreenshot = _screenshotKeywords.any((kw) => pathLower.contains(kw));

    // ── 3. ML Kit 图像标注（通用中文标签，离线 bundled 模型） ───────────
    final mlkitTags = await _extractMlKitTags(file);

    // ── 4. 解码图像（使用缩略图防止 OOM） ───────────────────────────────
    final targetBytes = thumbBytes ?? await file.readAsBytes();
    final decodedImage = await compute(img.decodeImage, targetBytes);

    double blurScore = 0.0;
    double colorWarmth = 0.0;
    double dominantHue = 0.0;
    // Phase 2：MobileCLIP 就绪后从 null 改为真实向量
    Uint8List? semanticVector;

    if (decodedImage != null) {
      // 4a. 模糊度（子线程）
      blurScore = await compute(_calculateBlurScore, decodedImage);

      // 4b. 主色调 + 冷暖度（子线程）
      final colorResult = await compute(_calculateColorFeatures, decodedImage);
      dominantHue = colorResult[0];
      colorWarmth = colorResult[1];

      // 4c. Phase 2 预留：MobileCLIP 语义向量提取
      // semanticVector = await _extractMobileCLIPVector(decodedImage);
    }

    // ── 5. 写库（isAnalyzed=true 表明已完成全管线分析） ─────────────────
    await (database.update(database.images)
          ..where((tbl) => tbl.id.equals(imageId)))
        .write(ImagesCompanion(
      hasText: Value(hasText),
      isScreenshot: Value(isScreenshot),
      blurScore: Value(blurScore),
      colorWarmth: Value(colorWarmth),
      dominantHue: Value(dominantHue),
      semanticVector:
          semanticVector != null ? Value(semanticVector) : const Value.absent(),
      tags: mlkitTags.isNotEmpty ? Value(mlkitTags.join(', ')) : const Value.absent(),
      isAnalyzed: const Value(true),
    ));
  }

  // ===========================================================================
  // ML Kit 图像标注（bundled on-device，完全离线）
  // ===========================================================================

  /// 返回置信度 ≥ 0.65 的中文标签列表（最多 5 个），按置信度降序。
  Future<List<String>> _extractMlKitTags(File file) async {
    try {
      final inputImage = InputImage.fromFile(file);
      final labels = await _imageLabeler.processImage(inputImage);

      // 过滤 + 中文化 + 去重
      final seen = <String>{};
      final result = <String>[];
      for (final label in labels) {
        if (label.confidence < 0.65) continue;
        final zh = MlKitZhLabels.translate(label.label);
        if (seen.add(zh)) {
          result.add(zh);
          if (result.length >= 5) break;
        }
      }
      return result;
    } catch (e) {
      debugPrint('ML Kit 标注失败: $e');
      return [];
    }
  }

  // ===========================================================================
  // OCR
  // ===========================================================================

  Future<bool> _detectText(File file) async {
    try {
      final inputImage = InputImage.fromFile(file);
      final result = await _textRecognizer.processImage(inputImage);
      return result.text.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // 图像算法（静态函数，运行在 compute 子线程）
  // ===========================================================================

  static double _calculateBlurScore(img.Image image) {
    final resized = img.copyResize(image, width: 256, height: 256);
    final gray = img.grayscale(resized);
    double sum = 0, sqSum = 0;
    int count = 0;
    for (int y = 1; y < gray.height - 1; y++) {
      for (int x = 1; x < gray.width - 1; x++) {
        final t = gray.getPixel(x, y - 1).r.toDouble();
        final b = gray.getPixel(x, y + 1).r.toDouble();
        final l = gray.getPixel(x - 1, y).r.toDouble();
        final r = gray.getPixel(x + 1, y).r.toDouble();
        final c = gray.getPixel(x, y).r.toDouble();
        final lap = t + b + l + r - 4 * c;
        sum += lap;
        sqSum += lap * lap;
        count++;
      }
    }
    if (count == 0) return 0.0;
    final mean = sum / count;
    return (sqSum / count) - (mean * mean);
  }

  /// 计算主色调（dominant hue, 0–360°）和冷暖度（color warmth, -1.0 ~ +1.0）
  static List<double> _calculateColorFeatures(img.Image image) {
    final small = img.copyResize(image, width: 32, height: 32);
    double totalR = 0, totalG = 0, totalB = 0;
    int count = 0;
    for (final pixel in small) {
      totalR += pixel.r / 255.0;
      totalG += pixel.g / 255.0;
      totalB += pixel.b / 255.0;
      count++;
    }
    if (count == 0) return [0.0, 0.0];
    final avgR = totalR / count;
    final avgG = totalG / count;
    final avgB = totalB / count;
    final colorWarmth = (avgR - avgB).clamp(-1.0, 1.0);
    final hue = _rgbToHue(avgR, avgG, avgB);
    return [hue, colorWarmth];
  }

  static double _rgbToHue(double r, double g, double b) {
    final maxC = max(r, max(g, b));
    final minC = min(r, min(g, b));
    final delta = maxC - minC;
    if (delta < 1e-6) return 0.0;
    double hue;
    if (maxC == r) {
      hue = 60.0 * (((g - b) / delta) % 6);
    } else if (maxC == g) {
      hue = 60.0 * (((b - r) / delta) + 2);
    } else {
      hue = 60.0 * (((r - g) / delta) + 4);
    }
    return hue < 0 ? hue + 360.0 : hue;
  }

  // ===========================================================================
  // Phase 2 预留：MobileCLIP TFLite 语义向量
  // （mobileclip_s0_image_encoder.tflite 就绪后取消注释）
  // ===========================================================================

  // Future<void> _initMobileclipIfNeeded() async {
  //   if (_mobileclipInterpreter != null) return;
  //   try {
  //     _mobileclipInterpreter =
  //         await Interpreter.fromAsset('assets/models/mobileclip_s0.tflite');
  //   } catch (e) {
  //     debugPrint('MobileCLIP 加载失败: $e');
  //   }
  // }

  // static Float32List _prepareMobileclipInput(img.Image image) {
  //   final resized = img.copyResize(image, width: 256, height: 256);
  //   final input = Float32List(256 * 256 * 3);
  //   int idx = 0;
  //   for (final p in resized) {
  //     input[idx++] = p.r / 255.0;
  //     input[idx++] = p.g / 255.0;
  //     input[idx++] = p.b / 255.0;
  //   }
  //   return input;
  // }

  // Future<Uint8List?> _extractMobileCLIPVector(img.Image image) async {
  //   await _initMobileclipIfNeeded();
  //   if (_mobileclipInterpreter == null) return null;
  //   try {
  //     final input = await compute(_prepareMobileclipInput, image);
  //     final inputTensor = input.reshape([1, 256, 256, 3]);
  //     final output = List.filled(512, 0.0).reshape([1, 512]);
  //     _mobileclipInterpreter!.run(inputTensor, output);
  //     final vector = (output[0] as List<double>).cast<double>();
  //     return Float32List.fromList(vector).buffer.asUint8List();
  //   } catch (e) {
  //     debugPrint('MobileCLIP 推理失败: $e');
  //     return null;
  //   }
  // }
}
