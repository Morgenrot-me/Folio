// feature_extractor_service.dart
// AI 特征提取服务（双管线并行）：
//   管线一：ML Kit ImageLabeler（通用物体中文标签，bundled 离线）
//   管线二：Places365 TFLite（场景地点中文标签，完全离线）
// 附加特征：拉普拉斯模糊度 + HSL 主色调/冷暖度 + 截图路径检测
// 标签后处理：LabelNormalizer 同义词合并 + 黑名单过滤
//
// 性能设计：
//   - AI 阶段（extractFeaturesForImage）：跳过 OCR，ML Kit 与 Places365 并行执行
//   - OCR 阶段（extractOcrForImage）：后台静默，过滤无意义内容再存库
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
import '../constants/label_normalizer.dart';

/// 多厂商截图路径关键字（小写匹配）
const _screenshotKeywords = [
  'screenshot', 'screen_shot', 'screencap', 'screen-shot',
  'shot_', 'capture', '截图', '截屏', 'screenrecord',
];

/// Places365 预处理：ImageNet 均值与标准差
const _p365Mean = [0.485, 0.456, 0.406];
const _p365Std  = [0.229, 0.224, 0.225];

// ── OCR 过滤规则 ─────────────────────────────────────────────────────────────
/// 有意义文字的最短长度（过短的通常是噪声或 UI 标签）
const _kOcrMinLength = 10;

/// 几乎纯数字/符号的正则（如时间戳、电池百分比等，无语义价值）
final _kOcrNoisyPattern = RegExp(r'^[\d\s:\.%\-\+/]+$');

/// 无意义 UI 字符串黑名单（精确匹配，忽略前后空格）
const _kOcrUiBlacklist = {
  '好的', '确定', '取消', '返回', '更多', '设置', '删除', '分享',
  'OK', 'Cancel', 'Back', 'More', 'Settings', 'Delete', 'Share',
  '已读', '未读', '发送', '接收',
};

/// OCR 文字最大保存长度（防止截图含大量长文本占满存储）
const _kOcrMaxChars = 500;

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
    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.65),
    );
  }

  /// 初始化 Places365（懒加载，首次调用时执行）
  Future<void> _initPlaces365IfNeeded() async {
    if (_places365Ready) return;
    try {
      _places365Interpreter = await Interpreter.fromAsset(
        'assets/models/places365_resnet18.tflite',
        options: InterpreterOptions()..threads = 2,
      );
      final raw = await rootBundle.loadString(
          'assets/models/places365_labels_zh.txt');
      _places365Labels = raw
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      _places365Ready = true;
      debugPrint('Places365: 模型加载完成，标签 ${_places365Labels.length} 个');
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

  // ===========================================================================
  // ★ Phase A：快速 AI 特征提取（跳过 OCR，ML Kit + Places365 并行）
  // ===========================================================================

  /// 核心调度：对单张图片执行 AI 特征提取并落库（不跑 OCR，存 ocrText=NULL）
  ///
  /// 优化亮点：
  ///   1. 完全跳过 OCR（降低每张 200–500ms 耗时）
  ///   2. ML Kit 与 Places365 通过 Future.wait 并行执行
  ///   3. ML Kit 返回最多 10 条标签（原来 5 条）
  Future<void> extractFeaturesForImage(String imageId, String filePath,
      [Uint8List? thumbBytes]) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    // ── 1. 截图检测（纯路径字符串匹配，无 IO，耗时 < 1ms）
    final pathLower = filePath.toLowerCase();
    final isScreenshot =
        _screenshotKeywords.any((kw) => pathLower.contains(kw));

    // ── 2. 解码图像（使用缩略图防止 OOM）
    final targetBytes = thumbBytes ?? await file.readAsBytes();
    final decodedImage = await compute(img.decodeImage, targetBytes);

    // ── 3. 并行：ML Kit 图像标注 + Places365 + 图像算法
    late List<String> mlkitTags;
    late List<String> places365Tags;
    Uint8List? semanticVector;
    double blurScore = 0.0;
    double colorWarmth = 0.0;
    double dominantHue = 0.0;

    // ML Kit 可以直接用文件，无需等 decodedImage
    final mlkitFuture = _extractMlKitTags(file);

    // Places365 + 图像算法需要 decodedImage
    if (decodedImage != null) {
      final results = await Future.wait([
        mlkitFuture,
        _extractPlaces365Result(decodedImage).then((r) {
          places365Tags = r.tags;
          semanticVector = r.vector;
          return r.tags; // 返回值只是为了 wait 类型统一
        }),
        compute(_calculateBlurScore, decodedImage).then((v) {
          blurScore = v;
          return <String>[];
        }),
        compute(_calculateColorFeatures, decodedImage).then((v) {
          dominantHue = v[0];
          colorWarmth = v[1];
          return <String>[];
        }),
      ]);
      mlkitTags = results[0];
    } else {
      // 解码失败时，ML Kit 仍可跑（直接从文件）
      mlkitTags = await mlkitFuture;
      places365Tags = [];
    }

    // ── 4. 合并标签（Places365 场景优先 + ML Kit 物体）
    final rawTags = [...places365Tags, ...mlkitTags];
    final allTags = LabelNormalizer.normalize(rawTags, maxCount: 8);
    final tagsString = allTags.isNotEmpty ? allTags.join(', ') : null;

    // ── 5. 写库（ocrText 保持 NULL，待后台 OCR 阶段填充）
    await (database.update(database.images)
          ..where((tbl) => tbl.id.equals(imageId)))
        .write(ImagesCompanion(
      isScreenshot: Value(isScreenshot),
      blurScore:    Value(blurScore),
      colorWarmth:  Value(colorWarmth),
      dominantHue:  Value(dominantHue),
      semanticVector: semanticVector != null
          ? Value(semanticVector!)
          : const Value.absent(),
      tags:        tagsString != null
          ? Value(tagsString)
          : const Value.absent(),
      // hasText 暂不更新（等 OCR 阶段填充）
      isAnalyzed:  const Value(true),
      // ocrText 保持 NULL（表示"待 OCR"）
    ));
  }

  // ===========================================================================
  // ★ Phase B：后台静默 OCR（过滤无意义内容，再更新 hasText + ocrText）
  // ===========================================================================

  /// 对单张图片执行 OCR 并更新数据库。
  ///
  /// 过滤规则：
  ///   - 文字 < 10 字符 → 存 ''（无意义，设 hasText=false）
  ///   - 纯数字/符号 → 存 ''
  ///   - UI 黑名单词 → 过滤后剩余部分继续判断
  ///   - 合格文字截断至 500 字符上限
  Future<void> extractOcrForImage(String imageId, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      // 文件不存在，标记为已 OCR（避免重试）
      await _saveOcrResult(imageId, '', false);
      return;
    }

    try {
      final inputImage = InputImage.fromFile(file);
      final result = await _textRecognizer.processImage(inputImage);
      final raw = result.text.trim();

      final filtered = _filterOcrText(raw);
      final hasText = filtered.isNotEmpty;
      await _saveOcrResult(imageId, filtered, hasText);
    } catch (e) {
      debugPrint('OCR 失败 ($filePath): $e');
      // OCR 失败不重试，存空字符串标记已处理
      await _saveOcrResult(imageId, '', false);
    }
  }

  Future<void> _saveOcrResult(
      String imageId, String text, bool hasText) async {
    await (database.update(database.images)
          ..where((tbl) => tbl.id.equals(imageId)))
        .write(ImagesCompanion(
      ocrText: Value(text),
      hasText: Value(hasText),
    ));
  }

  /// 过滤 OCR 原始文字，返回有意义的内容（无意义返回 ''）
  static String _filterOcrText(String raw) {
    if (raw.isEmpty) return '';

    // 按行分割，逐行过滤
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .where((l) => l.length >= 2)            // 单字/单符号跳过
        .where((l) => !_kOcrNoisyPattern.hasMatch(l)) // 纯数字/符号行跳过
        .where((l) => !_kOcrUiBlacklist.contains(l)) // UI 黑名单行跳过
        .toList();

    final joined = lines.join('\n');
    if (joined.length < _kOcrMinLength) return ''; // 总长度不足，无意义

    // 截断上限
    return joined.length > _kOcrMaxChars
        ? joined.substring(0, _kOcrMaxChars)
        : joined;
  }

  // ===========================================================================
  // ML Kit 图像标注
  // ===========================================================================

  /// 返回置信度 ≥ 0.65 的中文标签（最多 10 个）
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
          if (result.length >= 10) break; // 最多 10 条
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

  Future<({List<String> tags, Uint8List? vector})>
      _extractPlaces365Result(img.Image image) async {
    await _initPlaces365IfNeeded();
    if (!_places365Ready || _places365Interpreter == null) {
      return (tags: <String>[], vector: null);
    }
    try {
      final inputData = await compute(_prepareP365Input, image);
      final outFeature = [List.filled(512, 0.0)];
      final outLogits  = [List.filled(365, 0.0)];
      final outputs    = {0: outFeature, 1: outLogits};
      _places365Interpreter!.runForMultipleInputs(
        [inputData.reshape([1, 224, 224, 3])],
        outputs,
      );

      final featureList = (outFeature[0] as List<dynamic>).cast<double>();
      final vectorBytes =
          Float32List.fromList(featureList).buffer.asUint8List();

      final logits  = (outLogits[0] as List<dynamic>).cast<double>();
      final softmax = _softmax(logits);
      final indexed = softmax.asMap().entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final tags = <String>[];
      for (final entry in indexed.take(3)) {
        if (entry.value < 0.15) break;
        if (entry.key < _places365Labels.length) {
          tags.add(_places365Labels[entry.key]);
        }
      }
      return (tags: tags, vector: vectorBytes);
    } catch (e) {
      debugPrint('Places365 推理失败: $e');
      return (tags: <String>[], vector: null);
    }
  }

  static Float32List _prepareP365Input(img.Image image) {
    final resized = img.copyResize(image, width: 224, height: 224);
    final input = Float32List(224 * 224 * 3);
    int idx = 0;
    for (final p in resized) {
      input[idx++] = (p.r / 255.0 - _p365Mean[0]) / _p365Std[0];
      input[idx++] = (p.g / 255.0 - _p365Mean[1]) / _p365Std[1];
      input[idx++] = (p.b / 255.0 - _p365Mean[2]) / _p365Std[2];
    }
    return input;
  }

  static List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce((a, b) => a > b ? a : b);
    final exp = logits.map((x) => dart_math_exp(x - maxVal)).toList();
    final sum = exp.reduce((a, b) => a + b);
    return exp.map((x) => x / sum).toList();
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
    return [_rgbToHue(avgR, avgG, avgB), (avgR - avgB).clamp(-1.0, 1.0)];
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
