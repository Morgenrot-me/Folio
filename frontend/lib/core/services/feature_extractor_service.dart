import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart';

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
      // 模型应放置于 assets/models/mobileclip.tflite
      _interpreter = await Interpreter.fromAsset('assets/models/mobileclip.tflite');
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
  Future<void> extractFeaturesForImage(String imageId, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    // 1. 文字检测 (ML Kit)
    bool hasText = await _detectText(file);

    // 2. 简易截图检测 (基于常见的截图命名路径及文件名)
    bool isScreenshot = filePath.toLowerCase().contains('screenshot');

    // 3. 图像像素特征解析 (基于 image 库计算颜色和清晰度)
    final imageBytes = await file.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);
    
    double blurScore = 0.0;
    double colorWarmth = 0.0;
    double dominantHue = 0.0;
    
    if (decodedImage != null) {
      blurScore = _calculateBlurScore(decodedImage);
      // TODO: _calculateColorFeatures
    }

    // 4. 语义向量推理 (TFLite)
    Uint8List? semanticVector = await _extractSemanticVector(file);

    // 5. 更新回数据库
    await (database.update(database.images)..where((tbl) => tbl.id.equals(imageId))).write(
      ImagesCompanion(
        hasText: Value(hasText),
        isScreenshot: Value(isScreenshot),
        blurScore: Value(blurScore),
        colorWarmth: Value(colorWarmth),
        dominantHue: Value(dominantHue),
        semanticVector: semanticVector != null ? Value(semanticVector) : const Value.absent(),
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

  double _calculateBlurScore(img.Image image) {
    // TODO: 实现精准的拉普拉斯边缘方差检测
    return 100.0; 
  }

  Future<Uint8List?> _extractSemanticVector(File file) async {
    if (_interpreter == null) return null;
    // TODO: 执行 MobileCLIP 的 Tensor 图像前处理、推理调用，最后转化出字节串
    return null; 
  }
}
