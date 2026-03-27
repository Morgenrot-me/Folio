// feature_extractor_service.dart
// AI 特征提取服务（双管线）：
//   管线一：ML Kit ImageLabeler（通用物体中文标签，bundled 离线）
//   管线二：Places365 TFLite（场景地点中文标签，完全离线，43 MB 模型）
// 附加特征：ML Kit OCR + 拉普拉斯模糊度 + HSL 主色调/冷暖度 + 截图路径检测
// Phase 2 预留：MobileCLIP TFLite 语义向量接口（代码槽位已注释保留）

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
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

/// Places365 预处理：ImageNet 均值与标准差
const _p365Mean = [0.485, 0.456, 0.406];
const _p365Std  = [0.229, 0.224, 0.225];

class FeatureExtractorService {
  final AppDatabase database;

  late TextRecognizer _textRecognizer;
  late ImageLabeler _imageLabeler;

  // Places365 TFLite
  Interpreter? _places365Interpreter;
  List<String> _places365Labels = [];
  bool _places365Ready = false;

  /// Phase 2 占位符：MobileCLIP TFLite 解释器（模型文件就绪后启用）
  Interpreter? _mobileclipInterpreter;

  FeatureExtractorService(this.database) {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);
    // Bundled on-device 模式：confidence 阈值 0.65，完全离线
    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.65),
    );
  }

  /// 初始化 Places365（懒加载，首次调用时执行）
  Future<void> _initPlaces365IfNeeded() async {
    if (_places365Ready) return;
    try {
      // 加载模型
      _places365Interpreter = await Interpreter.fromAsset(
        'assets/models/places365_resnet18.tflite',
        options: InterpreterOptions()..threads = 2,
      );
      // 加载中文标签
      final raw = await rootBundle.loadString(
          'assets/models/places365_labels_zh.txt');
      _places365Labels = raw
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      _places365Ready = true;
      debugPrint(
          'Places365: 模型加载完成，标签 ${_places365Labels.length} 个');
    } catch (e) {
      debugPrint('Places365: 加载失败 => $e');
    }
  }

  void dispose() {
    _textRecognizer.close();
    _imageLabeler.close();
    _places365Interpreter?.close();
    _mobileclipInterpreter?.close();
  }

  /// 核心调度：对单张图片执行全维度特征提取并落库
  Future<void> extractFeaturesForImage(String imageId, String filePath,
      [Uint8List? thumbBytes]) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    // ── 1. OCR 文字检测 ────────────────────────────────────────────────────
    final hasText = await _detectText(file);

    // ── 2. 截图检测（多厂商路径关键字） ──────────────────────────────────
    final pathLower = filePath.toLowerCase();
    final isScreenshot =
        _screenshotKeywords.any((kw) => pathLower.contains(kw));

    // ── 3. ML Kit 图像标注（通用中文标签，离线 bundled 模型） ─────────────
    final mlkitTags = await _extractMlKitTags(file);

    // ── 4. 解码图像（使用缩略图防止 OOM） ─────────────────────────────────
    final targetBytes = thumbBytes ?? await file.readAsBytes();
    final decodedImage = await compute(img.decodeImage, targetBytes);

    double blurScore = 0.0;
    double colorWarmth = 0.0;
    double dominantHue = 0.0;
    Uint8List? semanticVector; // Phase 2 MobileCLIP 就绪后填充

    List<String> places365Tags = [];

    if (decodedImage != null) {
      // 4a. 模糊度（子线程）
      blurScore = await compute(_calculateBlurScore, decodedImage);

      // 4b. 主色调 + 冷暖度（子线程）
      final colorResult =
          await compute(_calculateColorFeatures, decodedImage);
      dominantHue = colorResult[0];
      colorWarmth  = colorResult[1];

      // 4c. Places365 场景标签
      places365Tags = await _extractPlaces365Tags(decodedImage);

      // 4d. Phase 2 预留：MobileCLIP 语义向量
      // semanticVector = await _extractMobileCLIPVector(decodedImage);
    }

    // ── 5. 合并标签（ML Kit + Places365，去重，最多 8 个） ────────────────
    final allTags = <String>[];
    final seen = <String>{};
    for (final t in [...mlkitTags, ...places365Tags]) {
      if (seen.add(t)) {
        allTags.add(t);
        if (allTags.length >= 8) break;
      }
    }
    final tagsString = allTags.isNotEmpty ? allTags.join(', ') : null;

    // ── 6. 写库 ───────────────────────────────────────────────────────────
    await (database.update(database.images)
          ..where((tbl) => tbl.id.equals(imageId)))
        .write(ImagesCompanion(
      hasText:      Value(hasText),
      isScreenshot: Value(isScreenshot),
      blurScore:    Value(blurScore),
      colorWarmth:  Value(colorWarmth),
      dominantHue:  Value(dominantHue),
      semanticVector: semanticVector != null
          ? Value(semanticVector)
          : const Value.absent(),
      tags:        tagsString != null
          ? Value(tagsString)
          : const Value.absent(),
      isAnalyzed:  const Value(true),
    ));
  }

  // ===========================================================================
  // ML Kit 图像标注
  // ===========================================================================

  /// 返回置信度 ≥ 0.65 的中文标签（最多 5 个）
  Future<List<String>> _extractMlKitTags(File file) async {
    try {
      final inputImage = InputImage.fromFile(file);
      final labels = await _imageLabeler.processImage(inputImage);
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
  // Places365 TFLite 场景标签
  // ===========================================================================

  /// 返回 Top-3 场景标签（概率 > 0.05）
  Future<List<String>> _extractPlaces365Tags(img.Image image) async {
    await _initPlaces365IfNeeded();
    if (!_places365Ready || _places365Interpreter == null) return [];
    try {
      final inputData =
          await compute(_prepareP365Input, image);
      final output =
          List.generate(1, (_) => List.filled(365, 0.0));
      _places365Interpreter!.run(
          inputData.reshape([1, 224, 224, 3]), output);

      final logits = (output[0] as List<double>);
      final softmax = _softmax(logits);

      // 取 Top-3，概率阈值 0.05
      final indexed = softmax.asMap().entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final result = <String>[];
      for (final entry in indexed.take(3)) {
        if (entry.value < 0.05) break;
        if (entry.key < _places365Labels.length) {
          result.add(_places365Labels[entry.key]);
        }
      }
      return result;
    } catch (e) {
      debugPrint('Places365 推理失败: $e');
      return [];
    }
  }

  /// 预处理（静态函数，在 compute 子线程执行）
  static Float32List _prepareP365Input(img.Image image) {
    final resized = img.copyResize(image, width: 224, height: 224);
    final input = Float32List(224 * 224 * 3);
    int idx = 0;
    for (final p in resized) {
      // ImageNet mean/std 归一化
      input[idx++] = (p.r / 255.0 - _p365Mean[0]) / _p365Std[0];
      input[idx++] = (p.g / 255.0 - _p365Mean[1]) / _p365Std[1];
      input[idx++] = (p.b / 255.0 - _p365Mean[2]) / _p365Std[2];
    }
    return input;
  }

  static List<double> _softmax(List<double> logits) {
    final max = logits.reduce((a, b) => a > b ? a : b);
    final exp = logits.map((x) => dart_math_exp(x - max)).toList();
    final sum = exp.reduce((a, b) => a + b);
    return exp.map((x) => x / sum).toList();
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
  // ===========================================================================

  // Future<Uint8List?> _extractMobileCLIPVector(img.Image image) async { ... }
}

/// dart:math exp 的顶层别名，供 _softmax 调用
double dart_math_exp(double x) => exp(x);
