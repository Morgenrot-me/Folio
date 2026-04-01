import 'package:drift/drift.dart';

/// 图片基础信息与特征数据表
class Images extends Table {
  TextColumn get id => text()(); // 稳定ID，基于路径哈希
  TextColumn get filePath => text()();
  TextColumn get fileName => text()();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  IntColumn get fileSize => integer()();
  IntColumn get takenAt => integer().nullable()(); // Unix时间戳
  IntColumn get indexedAt => integer()();
  IntColumn get phash => integer().nullable()(); // 64位哈希
  BlobColumn get semanticVector => blob()(); // Places365 ResNet18 中间特征（非 CLIP 空间，不用于文字搜索）
  BoolColumn get isScreenshot => boolean().withDefault(const Constant(false))();
  BoolColumn get hasText => boolean().withDefault(const Constant(false))();
  /// v4: OCR提取的过滤后文字内容
  ///   NULL  = 尚未执行 OCR（后台任务待处理）
  ///   ''    = OCR已完成但无有效内容
  ///   其他  = 过滤后的有效文字
  TextColumn get ocrText => text().nullable()();
  TextColumn get tags => text().nullable()(); // AI标签（逗号分隔，最多8个）
  RealColumn get blurScore => real()();
  RealColumn get dominantHue => real()();
  RealColumn get colorWarmth => real()();
  /// v3: 可靠标记 AI 特征提取管线是否完整跑过，替代不可靠的 blurScore==0 判断
  BoolColumn get isAnalyzed => boolean().withDefault(const Constant(false))();
  /// v5: MobileCLIP 图像语义向量（512维 float32 BLOB）
  ///   与文字编码器在同一 CLIP 语义空间，支持余弦相似度文字搜索
  ///   NULL = 尚未跑 MobileCLIP 推理
  BlobColumn get clipVector => blob().nullable()();
  TextColumn get clusterId => text().nullable()(); // 外键 clusters.id
  RealColumn get gpsLat => real().nullable()();
  RealColumn get gpsLon => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
