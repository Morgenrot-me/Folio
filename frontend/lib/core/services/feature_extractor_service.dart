// feature_extractor_service.dart
// AI 特征提取服务：TFLite MobileNet 语义向量 + MLKit OCR + 拉普拉斯模糊度 + 色调/冷暖度 + 截图检测
// 改善：
//   - 实现 dominantHue（主色调 0-360°）和 colorWarmth（冷暖度 -1~1）
//   - 截图检测扩展为多厂商路径关键字列表（覆盖 MIUI/EMUI/ColorOS 等）

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart';
import '../constants/imagenet_labels.dart';

/// 多厂商截图路径关键字（小写匹配）
const _screenshotKeywords = [
  'screenshot',   // 通用
  'screen_shot',
  'screencap',
  'screen-shot',
  'shot_',        // MIUI: /Shot_xxx/
  'capture',      // 某些 HuaWei
  '截图',          // 中文路径
  '截屏',
  'screenrecord', // 屏幕录制帧
];

class FeatureExtractorService {
  final AppDatabase database;
  late TextRecognizer _textRecognizer;
  Interpreter? _interpreter;

  bool get isModelLoaded => _interpreter != null;

  FeatureExtractorService(this.database) {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);
  }

  /// 懒加载 TFLite 模型
  Future<void> initModelIfNeeded() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/mobilenet.tflite');
      debugPrint('FeatureExtractorService: MobileNet 加载完成');
    } catch (e) {
      debugPrint('FeatureExtractorService: 模型加载失败 => $e');
    }
  }

  void dispose() {
    _textRecognizer.close();
    _interpreter?.close();
  }

  /// 核心调度：对单张图片执行全维度特征提取并落库
  Future<void> extractFeaturesForImage(String imageId, String filePath,
      [Uint8List? thumbBytes]) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    await initModelIfNeeded();

    // 1. OCR 文字检测
    final hasText = await _detectText(file);

    // 2. 多关键字截图检测
    final pathLower = filePath.toLowerCase();
    final isScreenshot =
        _screenshotKeywords.any((kw) => pathLower.contains(kw));

    // 3. 解码图像（使用缩略图防止 OOM）
    final targetBytes = thumbBytes ?? await file.readAsBytes();
    final decodedImage = await compute(img.decodeImage, targetBytes);

    double blurScore = 0.0;
    double colorWarmth = 0.0;
    double dominantHue = 0.0;
    Uint8List? semanticVector;

    if (decodedImage != null) {
      // 3a. 模糊度（子线程）
      blurScore = await compute(_calculateBlurScore, decodedImage);

      // 3b. 主色调 + 冷暖度（子线程）
      final colorResult = await compute(_calculateColorFeatures, decodedImage);
      dominantHue = colorResult[0];
      colorWarmth = colorResult[1];

      // 4. 语义向量（TFLite MobileNet）
      semanticVector = await _extractSemanticVector(decodedImage);
    }

    // 5. Top-6 可读标签
    String? topTagsString;
    if (semanticVector != null && semanticVector.isNotEmpty) {
      try {
        final floats = Float32List.view(semanticVector.buffer);
        final indexed = floats.toList().asMap().entries.toList();
        indexed.sort((a, b) => b.value.compareTo(a.value));
        final topTags = <String>[];
        for (int i = 0; i < 6; i++) {
          if (indexed[i].key < ImageNetLabels.labels.length) {
            topTags.add(ImageNetLabels.labels[indexed[i].key]);
          }
        }
        topTagsString = topTags.join(', ');
      } catch (e) {
        debugPrint('提取可读标签失败: $e');
      }
    }

    // 6. 写库，isAnalyzed=true 表明本记录已完成全管线分析
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
      tags: topTagsString != null ? Value(topTagsString) : const Value.absent(),
      isAnalyzed: const Value(true),
    ));
  }

  // =========================================================================
  // 具体算法实现
  // =========================================================================

  Future<bool> _detectText(File file) async {
    try {
      final inputImage = InputImage.fromFile(file);
      final result = await _textRecognizer.processImage(inputImage);
      return result.text.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

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
  /// 采样 32×32 缩略图，遍历所有像素取均值，性能友好且足够准确。
  static List<double> _calculateColorFeatures(img.Image image) {
    // 缩到 32×32 快速采样，足够表征整体色调
    final small = img.copyResize(image, width: 32, height: 32);

    double totalR = 0, totalG = 0, totalB = 0;
    int count = 0;

    // 累加所有像素 RGB
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

    // 冷暖度 = (红+黄权重) - (蓝+青权重)，范围 -1 ~ +1
    // 简化：warmth ≈ (R - B)，暖色调（红/橙/黄）R>B，冷色调（蓝/青）B>R
    final colorWarmth = (avgR - avgB).clamp(-1.0, 1.0);

    // 主色调：将均值 RGB 转为 HSL 取 H 值（0–360°）
    final hue = _rgbToHue(avgR, avgG, avgB);

    return [hue, colorWarmth];
  }

  /// RGB（0.0–1.0）→ HSL Hue（0–360°）
  static double _rgbToHue(double r, double g, double b) {
    final maxC = max(r, max(g, b));
    final minC = min(r, min(g, b));
    final delta = maxC - minC;
    if (delta < 1e-6) return 0.0; // 无彩色（灰色），色调无意义，定为 0°

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

  static Float32List _prepareTensorInput(img.Image decodedImage) {
    final resized = img.copyResize(decodedImage, width: 224, height: 224);
    final inputList = Float32List(224 * 224 * 3);
    int idx = 0;
    for (final p in resized) {
      inputList[idx++] = (p.r / 127.5) - 1.0;
      inputList[idx++] = (p.g / 127.5) - 1.0;
      inputList[idx++] = (p.b / 127.5) - 1.0;
    }
    return inputList;
  }

  Future<Uint8List?> _extractSemanticVector(img.Image decodedImage) async {
    if (_interpreter == null) return null;
    try {
      final inputList = await compute(_prepareTensorInput, decodedImage);
      final input = inputList.buffer.asFloat32List().reshape([1, 224, 224, 3]);
      final output = List.filled(1000, 0.0).reshape([1, 1000]);
      _interpreter!.run(input, output);
      final outputVector = (output[0] as List<double>).cast<double>();
      return Float32List.fromList(outputVector).buffer.asUint8List();
    } catch (e) {
      debugPrint('TFLite 推理失败: $e');
      return null;
    }
  }
}
