import 'package:drift/drift.dart';

/// 智能文件夹数据表
class SmartFolders extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text()();
  TextColumn get icon => text()();
  IntColumn get color => integer()(); // ARGB颜色
  TextColumn get rootRuleId => text().nullable()(); // 规则树根节点ID (外键)
  IntColumn get sortOrder => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get lastMatchedAt => integer()();
  TextColumn get exportPath => text().nullable()(); // 系统导出路径
  TextColumn get exportMode => text().nullable()(); // COPY或MOVE
  IntColumn get lastExportedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
