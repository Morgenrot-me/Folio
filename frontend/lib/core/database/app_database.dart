import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'tables/images.dart';
import 'tables/smart_folders.dart';
import 'tables/folder_rules.dart';
import 'tables/clusters.dart';
import 'tables/image_folder_map.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Images, SmartFolders, FolderRules, Clusters, ImageFolderMap])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3; // v3：新增 isAnalyzed 特征完成标志列

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        // 👇 SQLite 默认关闭外键约束，必须在每次连接时手动开启
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // v2：添加 tags 可读标签列
          await m.addColumn(images, images.tags);
        }
        if (from < 3) {
          // v3：添加 isAnalyzed 特征完成标志列（默认 false，兼容旧记录）
          await m.addColumn(images, images.isAnalyzed);
        }
      },
    );
  }

  /// 监听所有被索引的图片张数，形成动态流
  Stream<int> watchTotalImagesCount() {
    final countExp = images.id.count();
    final query = selectOnly(images)..addColumns([countExp]);
    return query.map((row) => row.read(countExp)!).watchSingle();
  }

  /// 监听已完成 AI 分析的图片数量
  Stream<int> watchAnalyzedImagesCount() {
    final countExp = images.id.count();
    final query = selectOnly(images)
      ..addColumns([countExp])
      ..where(images.isAnalyzed.equals(true));
    return query.map((row) => row.read(countExp)!).watchSingle();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'smart_gallery.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        // 同样在后台线程开启外键约束
        db.execute('PRAGMA foreign_keys = ON');
      },
    );
  });
}
