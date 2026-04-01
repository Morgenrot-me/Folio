// semantic_search_service.dart
// MobileCLIP 语义搜索服务：
//   - 加载 MobileCLIP 文本编码器 TFLite（mobileclip_s1_text.tflite）
//   - 加载 MobileCLIP 图像编码器 TFLite（mobileclip_s1_vision.tflite，用于再索引）
//   - 接受任意文字查询，编码为 512 维向量，与全库图片 clipVector 做余弦相似度排序
//
// 前提：
//   - images.clipVector 字段已填充 MobileCLIP 图像向量（由 FeatureExtractorService 写入）
//   - assets/models/mobileclip_s1_text.tflite 和 clip_vocab.json 已就位

import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../constants/clip_tokenizer.dart';
import '../database/app_database.dart';

/// 单条搜索结果
class SemanticSearchResult {
  final Image image;
  final double similarity; // 余弦相似度，范围 [-1, 1]

  const SemanticSearchResult({required this.image, required this.similarity});
}

class SemanticSearchService {
  final AppDatabase database;

  Interpreter? _textInterpreter;
  ClipTokenizer? _tokenizer;
  bool _ready = false;

  SemanticSearchService(this.database);

  // ── 初始化（懒加载，首次搜索时触发）────────────────────────────────────────

  Future<void> _initIfNeeded() async {
    if (_ready) return;
    try {
      _tokenizer = await ClipTokenizer.load();
      _textInterpreter = await Interpreter.fromAsset(
        'assets/models/mobileclip_s1_text.tflite',
        options: InterpreterOptions()..threads = 2,
      );
      _ready = true;
      debugPrint('SemanticSearchService: 文本编码器加载完成');
    } catch (e) {
      debugPrint('SemanticSearchService: 初始化失败 => $e');
    }
  }

  void dispose() {
    _textInterpreter?.close();
  }

  // ── 公开 API ──────────────────────────────────────────────────────────────

  /// 文字语义搜索
  ///
  /// [query]     用户输入的任意描述文字（中英文均可）
  /// [topK]      返回最多 K 张最相似的图片（默认 50）
  /// [threshold] 余弦相似度最低阈值（默认 0.18；CLIP 余弦相似度通常在 0.1-0.5 之间）
  Future<List<SemanticSearchResult>> searchByText(
    String query, {
    int topK = 50,
    double threshold = 0.18,
  }) async {
    await _initIfNeeded();
    if (!_ready || _textInterpreter == null || _tokenizer == null) {
      debugPrint('SemanticSearchService: 未就绪，返回空结果');
      return [];
    }

    // 1. Tokenize 文字
    final tokenIds = _tokenizer!.encode(query.trim());

    // 2. 文本编码器推理 → 512 维文本向量
    final textVector = await compute(_runTextInference, _TextInferenceArgs(
      interpreterAddress: _textInterpreter!.address,
      tokenIds: tokenIds,
    ));

    if (textVector == null) {
      debugPrint('SemanticSearchService: 文本推理失败');
      return [];
    }

    // 3. 读取全库含 clipVector 的图片
    final allImages = await (database.select(database.images)
          ..where((t) => t.clipVector.isNotNull()))
        .get();

    if (allImages.isEmpty) {
      debugPrint('SemanticSearchService: 暂无已索引 MobileCLIP 向量的图片');
      return [];
    }

    // 4. 在子线程中批量计算余弦相似度
    final results = await compute(_computeSimilarities, _SimilarityArgs(
      textVector:  textVector,
      images:      allImages,
      topK:        topK,
      threshold:   threshold,
    ));

    return results;
  }

  /// 检查是否有尚未填充 clipVector 的图片（供 UI 提示再索引进度）
  Future<int> countUnindexed() async {
    return (await (database.select(database.images)
              ..where((t) => t.clipVector.isNull()))
            .get())
        .length;
  }
}

// ── Isolate 任务：文本推理 ────────────────────────────────────────────────────

class _TextInferenceArgs {
  final int interpreterAddress;
  final Int32List tokenIds;
  const _TextInferenceArgs({
    required this.interpreterAddress,
    required this.tokenIds,
  });
}

/// 在 compute() 子线程中运行文本编码器推理
Float32List? _runTextInference(_TextInferenceArgs args) {
  try {
    final interpreter = Interpreter.fromAddress(args.interpreterAddress);
    // 输入：[1, 77] int32
    final input  = [args.tokenIds.toList()];
    // 输出：[1, 512] float32
    final output = [List<double>.filled(512, 0.0)];
    interpreter.run(input, output);
    return Float32List.fromList((output[0] as List<dynamic>).cast<double>());
  } catch (e) {
    debugPrint('_runTextInference 失败: $e');
    return null;
  }
}

// ── Isolate 任务：批量余弦相似度计算 ─────────────────────────────────────────

class _SimilarityArgs {
  final Float32List textVector;
  final List<Image> images;
  final int topK;
  final double threshold;
  const _SimilarityArgs({
    required this.textVector,
    required this.images,
    required this.topK,
    required this.threshold,
  });
}

List<SemanticSearchResult> _computeSimilarities(_SimilarityArgs args) {
  final tv    = args.textVector;
  final tvLen = tv.length; // 512

  final scored = <SemanticSearchResult>[];

  for (final img in args.images) {
    final blob = img.clipVector;
    if (blob == null || blob.length != tvLen * 4) continue;

    // BLOB → Float32List
    final iv = blob.buffer.asFloat32List(blob.offsetInBytes, tvLen);

    // 余弦相似度（向量已 L2 归一化，直接点积即可）
    var dot = 0.0;
    for (var i = 0; i < tvLen; i++) {
      dot += tv[i] * iv[i];
    }

    if (dot >= args.threshold) {
      scored.add(SemanticSearchResult(image: img, similarity: dot));
    }
  }

  // 按相似度降序，取 Top-K
  scored.sort((a, b) => b.similarity.compareTo(a.similarity));
  return scored.take(args.topK).toList();
}
