import 'package:drift/drift.dart';
import 'images.dart';
import 'smart_folders.dart';

/// 记录图片所在文件夹映射表
class ImageFolderMap extends Table {
  TextColumn get id => text()(); // UUID
  /// 外键：图片删除时级联删除映射记录
  TextColumn get imageId =>
      text().customConstraint('NOT NULL REFERENCES images(id) ON DELETE CASCADE')();
  /// 外键：文件夹删除时级联删除映射记录
  TextColumn get folderId =>
      text().customConstraint('NOT NULL REFERENCES smart_folders(id) ON DELETE CASCADE')();
  TextColumn get source => text()(); // 归属来源: AUTO / MANUAL
  IntColumn get assignedAt => integer()();
  BoolColumn get isPhysicalPrimary => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
