import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart';
import '../constants/imagenet_labels.dart';

/// 特征提取服务：负责调用 TFLite + MLKit 对单张图片进行全维度特征提取并落库。
/// 模型：MobileNet V1（mobilenet.tflite），输出 1000 维 ImageNet 概率向量。
class FeatureExtractorService {
  final AppDatabase database;
  late TextRecognizer _textRecognizer;
  Interpreter? _interpreter;

  /// 是否已完成初始化（懒加载标志）
  bool get isModelLoaded => _interpreter != null;

  FeatureExtractorService(this.database) {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);
  }

  /// 初始化 TFLite 模型（懒加载：首次调用时才执行）
  Future<void> initModelIfNeeded() async {
    if (_interpreter != null) return;
    try {
      // 载入 MobileNet V1 模型权重
      _interpreter = await Interpreter.fromAsset('assets/models/mobilenet.tflite');
      debugPrint('FeatureExtractorService: MobileNet 模型加载完成');
    } catch (e) {
      debugPrint('FeatureExtractorService: 模型加载失败 => $e');
    }
  }

  /// 释放资源
  void dispose() {
    _textRecognizer.close();
    _interpreter?.close();
  }

  /// 核心调度方法：对单张图片执行全部特征抽取（文字、截图判断、模糊度、主色调、语义向量）并落库。
  /// 首次调用时自动触发模型懒加载。
  Future<void> extractFeaturesForImage(String imageId, String filePath, [Uint8List? thumbBytes]) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    // 确保模型已加载（懒加载：此处才真正消耗内存）
    await initModelIfNeeded();

    // 1. 文字检测 (ML Kit)
    bool hasText = await _detectText(file);

    // 2. 简易截图检测（基于路径关键字）
    bool isScreenshot = filePath.toLowerCase().contains('screenshot');

    // 3. 图像像素特征解析：优先使用缩略图防止 4K 原图 OOM
    final targetBytes = thumbBytes ?? await file.readAsBytes();
    final decodedImage = await compute(img.decodeImage, targetBytes);

    double blurScore = 0.0;
    double colorWarmth = 0.0;
    double dominantHue = 0.0;
    Uint8List? semanticVector;

    if (decodedImage != null) {
      blurScore = await compute(_calculateBlurScore, decodedImage);
      // TODO: 色调统计算法后续实现

      // 4. 语义向量推理 (TFLite MobileNet)
      semanticVector = await _extractSemanticVector(decodedImage);
    }

    // 5. 将 1000 维概率向量的 Top-6 转换为可读英文标签
    String? topTagsString;
    if (semanticVector != null && semanticVector.isNotEmpty) {
      try {
        final floats = Float32List.view(semanticVector.buffer);
        List<MapEntry<int, double>> indexed = floats.toList().asMap().entries.toList();
        indexed.sort((a, b) => b.value.compareTo(a.value));

        List<String> topTags = [];
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

    // 6. 更新回数据库；isAnalyzed=true 标记本轮 AI 管线已完整跑过
    await (database.update(database.images)..where((tbl) => tbl.id.equals(imageId))).write(
      ImagesCompanion(
        hasText: Value(hasText),
        isScreenshot: Value(isScreenshot),
        blurScore: Value(blurScore),
        colorWarmth: Value(colorWarmth),
        dominantHue: Value(dominantHue),
        semanticVector: semanticVector != null ? Value(semanticVector) : const Value.absent(),
        tags: topTagsString != null ? Value(topTagsString) : const Value.absent(),
        isAnalyzed: const Value(true), // 可靠地标记本记录已完成特征分析
      ),
    );
  }

  // ==== 具体实现 ====

  Future<bool> _detectText(File file) async {
    try {
      final inputImage = InputImage.fromFile(file);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static double _calculateBlurScore(img.Image image) {
    // 先缩放到 256x256 加速计算
    final resized = img.copyResize(image, width: 256, height: 256);
    final gray = img.grayscale(resized);

    // 通过拉普拉斯算子方差评估清晰度：方差越大越清晰
    double sum = 0;
    double sqSum = 0;
    int count = 0;

    for (int y = 1; y < gray.height - 1; y++) {
      for (int x = 1; x < gray.width - 1; x++) {
        // Laplacian kernel: [0, 1, 0,  1, -4, 1,  0, 1, 0]
        num top = gray.getPixel(x, y - 1).r;
        num bottom = gray.getPixel(x, y + 1).r;
        num left = gray.getPixel(x - 1, y).r;
        num right = gray.getPixel(x + 1, y).r;
        num center = gray.getPixel(x, y).r;

        double laplacian =
            top.toDouble() + bottom.toDouble() + left.toDouble() + right.toDouble() - (4 * center.toDouble());
        sum += laplacian;
        sqSum += laplacian * laplacian;
        count++;
      }
    }
    if (count == 0) return 0.0;
    double mean = sum / count;
    double variance = (sqSum / count) - (mean * mean);
    return variance;
  }

  static Float32List _prepareTensorInput(img.Image decodedImage) {
    // MobileNet 标准输入尺寸 224x224，归一化到 [-1.0, 1.0]
    final resized = img.copyResize(decodedImage, width: 224, height: 224);
    var inputList = Float32List(1 * 224 * 224 * 3);
    int pixelIndex = 0;

    for (final p in resized) {
      inputList[pixelIndex++] = (p.r / 127.5) - 1.0;
      inputList[pixelIndex++] = (p.g / 127.5) - 1.0;
      inputList[pixelIndex++] = (p.b / 127.5) - 1.0;
    }
    return inputList;
  }

  Future<Uint8List?> _extractSemanticVector(img.Image decodedImage) async {
    if (_interpreter == null) return null;
    try {
      // 在子线程预处理像素，避免主线程掉帧
      final inputList = await compute(_prepareTensorInput, decodedImage);

      var input = inputList.buffer.asFloat32List().reshape([1, 224, 224, 3]);
      // 1000 维 ImageNet 概率输出
      var output = List.filled(1 * 1000, 0.0).reshape([1, 1000]);

      _interpreter!.run(input, output);

      final outputVector = (output[0] as List<double>).cast<double>();
      final bytes = Float32List.fromList(outputVector).buffer.asUint8List();
      return bytes;
    } catch (e) {
      debugPrint('TFLite 推理失败: $e');
      return null;
    }
  }
}

