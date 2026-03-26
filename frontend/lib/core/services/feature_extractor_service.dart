import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart';
import '../constants/imagenet_labels.dart';

class FeatureExtractorService {
  final AppDatabase database;
  late TextRecognizer _textRecognizer;
  Interpreter? _interpreter;

  FeatureExtractorService(this.database) {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);
  }

  /// 初始化 TFLite 模型
  Future<void> initModel() async {
    try {
      // 载入极限瘦身版的 MobileNet 引擎 
      _interpreter = await Interpreter.fromAsset('assets/models/mobilenet.tflite');
    } catch (e) {
      debugPrint('Error loading TFLite model: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _textRecognizer.close();
    _interpreter?.close();
  }

  /// 核心调度方法：对单张图片执行全部特征抽取（文字、截图判断、模糊度、主色调、语义向量）并落库
  Future<void> extractFeaturesForImage(String imageId, String filePath, [Uint8List? thumbBytes]) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    // 1. 文字检测 (ML Kit) - ML Kit 底层做了 C++ 内存复用防抖，可直接喂原文件
    bool hasText = await _detectText(file);

    // 2. 简易截图检测 (基于常见的截图命名路径及文件名)
    bool isScreenshot = filePath.toLowerCase().contains('screenshot');

    // 3. 图像像素特征解析 (基于 image 库计算颜色和清晰度)
    // 【致命闪退修复】：优先解析缩略图(thumbBytes)！如果按原路直接把原生几千万像素的 4K 照片转码，内存会飙升 200MB 以上直接被系统 OOM 查杀闪退！
    final targetBytes = thumbBytes ?? await file.readAsBytes();
    final decodedImage = await compute(img.decodeImage, targetBytes);
    
    double blurScore = 0.0;
    double colorWarmth = 0.0;
    double dominantHue = 0.0;
    Uint8List? semanticVector;
    
    if (decodedImage != null) {
      // 在计算前，如果图片太大，可选择先将整图缩到极限尺寸规避爆内存
      blurScore = await compute(_calculateBlurScore, decodedImage);
      // TODO: 色调统计算法后续加入，此处先行置位
      
      // 4. 语义向量推理 (TFLite)
      semanticVector = await _extractSemanticVector(decodedImage);
    }
    
    // 【点石成金】将毫无意义的张量浮点转换为人类能够直视的英文标签！
    String? topTagsString;
    if (semanticVector != null && semanticVector.isNotEmpty) {
      try {
        final floats = Float32List.view(semanticVector.buffer);
        // 保留原数组的值并捆绑其对应的 1000 个类目的原始 Index
        List<MapEntry<int, double>> indexed = floats.toList().asMap().entries.toList();
        // 根据置信概率打分从高到低倒叙排列
        indexed.sort((a, b) => b.value.compareTo(a.value));
        
        List<String> topTags = [];
        // 热更新：听从用户指令，一口气多抓取一倍标签，取前 6 个物体名词！
        for (int i = 0; i < 6; i++) {
          if (indexed[i].key < ImageNetLabels.labels.length) {
             topTags.add(ImageNetLabels.labels[indexed[i].key]);
          }
        }
        topTagsString = topTags.join(', ');
      } catch(e) {
        debugPrint('提取人类可读标签失败: $e');
      }
    }

    // 5. 更新回数据库 (含增容字段 tags)
    await (database.update(database.images)..where((tbl) => tbl.id.equals(imageId))).write(
      ImagesCompanion(
        hasText: Value(hasText),
        isScreenshot: Value(isScreenshot),
        blurScore: Value(blurScore),
        colorWarmth: Value(colorWarmth),
        dominantHue: Value(dominantHue),
        semanticVector: semanticVector != null ? Value(semanticVector) : const Value.absent(),
        tags: topTagsString != null ? Value(topTagsString) : const Value.absent(),
      ),
    );
  }

  // ==== 具体实现拆分 ====

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
    // 为提升计算速度，先将图片缩放到较小尺寸(如 256x256)后再应用边缘检测
    final resized = img.copyResize(image, width: 256, height: 256);
    final gray = img.grayscale(resized);
    
    // 手动计算局部 Laplacian Variance (拉普拉斯算子方差)
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
        
        double laplacian = top.toDouble() + bottom.toDouble() + left.toDouble() + right.toDouble() - (4 * center.toDouble());
        sum += laplacian;
        sqSum += laplacian * laplacian;
        count++;
      }
    }
    if (count == 0) return 0.0;
    double mean = sum / count;
    double variance = (sqSum / count) - (mean * mean);
    return variance; // 方差越小说明梯度变化越均衡，图片越模糊
  }

  static Float32List _prepareTensorInput(img.Image decodedImage) {
    // 💡 EfficientNet Lite0 模型专属的完美黄金裁切维度为 224x224
    final resized = img.copyResize(decodedImage, width: 224, height: 224);
    var inputList = Float32List(1 * 224 * 224 * 3);
    int pixelIndex = 0;
    
    // 💡 标准输入通常需要映射到 [-1.0, 1.0] 的浮点空间内
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
      // 通过子线程隔离，防止长达几万次的 Dart 原生 for 循环将主 UI 线程死锁而导致严重掉帧
      final inputList = await compute(_prepareTensorInput, decodedImage);
      
      // Reshape 成底层 C++ Tensor 库所需的三维立方体批次： [B, H, W, C]
      var input = inputList.buffer.asFloat32List().reshape([1, 224, 224, 3]);
      // 💡 取出 ImageNet 千类分发概率阵列 (1000 维) 来充当照片的万能聚类特征向量基准！
      var output = List.filled(1 * 1000, 0.0).reshape([1, 1000]);
      
      _interpreter!.run(input, output);
      
      final outputVector = (output[0] as List<double>).cast<double>();
      final bytes = Float32List.fromList(outputVector).buffer.asUint8List();
      return bytes;
    } catch(e) {
      debugPrint("TFLite 推理遭遇错误: $e");
      return null;
    }
  }
}
