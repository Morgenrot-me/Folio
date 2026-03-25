import 'package:drift/drift.dart';

/// 记录图片所在文件夹映射表
class ImageFolderMap extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get imageId => text()(); // 图片ID
  TextColumn get folderId => text()(); // 文件夹ID
  TextColumn get source => text()(); // 归属来源: AUTO / MANUAL
  IntColumn get assignedAt => integer()();
  BoolColumn get isPhysicalPrimary => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
