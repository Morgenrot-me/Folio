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
  BlobColumn get semanticVector => blob()(); // 512维向量 (BLOB float32x512)
  BoolColumn get isScreenshot => boolean().withDefault(const Constant(false))();
  BoolColumn get hasText => boolean().withDefault(const Constant(false))();
  TextColumn get tags => text().nullable()(); // NEW: 用以存储将张量解构出的小于 5 个的可读英文标签 (以逗号切割)
  RealColumn get blurScore => real()();
  RealColumn get dominantHue => real()();
  RealColumn get colorWarmth => real()();
  TextColumn get clusterId => text().nullable()(); // 外键 clusters.id
  RealColumn get gpsLat => real().nullable()();
  RealColumn get gpsLon => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
