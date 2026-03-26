import 'package:drift/drift.dart';

/// 图片聚类结果表
class Clusters extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text()(); // 聚类名
  BlobColumn get centroidVector => blob()(); // 中心特征向量 1000维 (float32x1000，与 MobileNet ImageNet 输出对齐)
  IntColumn get imageCount => integer()();
  IntColumn get createdAt => integer()();
  BoolColumn get isUserNamed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
