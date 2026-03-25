import 'package:drift/drift.dart';

/// 规则树结构表 (AND/OR/NOT逻辑节点)
class FolderRules extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get folderId => text()(); // 所属智能文件夹ID (外键)
  TextColumn get parentId => text().nullable()(); // 父节点ID
  TextColumn get nodeType => text()(); // AND / OR / NOT / LEAF
  TextColumn get featureType => text().nullable()(); // 仅LEAF节点有: IS_SCREENSHOT 等
  TextColumn get comparator => text().nullable()(); // 比较符
  TextColumn get value => text().nullable()(); // 比较值的JSON字符串

  @override
  Set<Column> get primaryKey => {id};
}
