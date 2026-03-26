import 'package:drift/drift.dart';
import 'smart_folders.dart';

/// 规则树结构表 (AND/OR/NOT逻辑节点)
class FolderRules extends Table {
  TextColumn get id => text()(); // UUID
  /// 外键：所属智能文件夹，文件夹删除时级联删除全部规则节点
  TextColumn get folderId =>
      text().customConstraint('NOT NULL REFERENCES smart_folders(id) ON DELETE CASCADE')();
  TextColumn get parentId => text().nullable()(); // 父节点ID
  TextColumn get nodeType => text()(); // AND / OR / NOT / LEAF
  TextColumn get featureType => text().nullable()(); // 仅LEAF节点有: IS_SCREENSHOT 等
  TextColumn get comparator => text().nullable()(); // 比较符
  TextColumn get value => text().nullable()(); // 比较值的JSON字符串

  @override
  Set<Column> get primaryKey => {id};
}
