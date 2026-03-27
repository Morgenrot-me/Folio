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
  /// 默认构造：用于前台主 Isolate（路径由 path_provider 自动解析）
  AppDatabase() : super(_openConnection());

  /// WorkManager 专用构造：直接传入已知路径的数据库文件
  /// WorkManager Isolate 同样可以调用 path_provider，但为了更清晰地控制
  /// 文件路径，提供此工厂方法
  AppDatabase.fromFile(File dbFile)
      : super(NativeDatabase.createInBackground(
          dbFile,
          setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
        ));

  @override
  int get schemaVersion => 4; // v4：新增 ocrText 字段（后台静默 OCR 结果）

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(images, images.tags);
        }
        if (from < 3) {
          await m.addColumn(images, images.isAnalyzed);
        }
        if (from < 4) {
          // v4：新增 OCR 文字字段，用原生 SQL 规避 addColumn 泛型限制
          await customStatement(
              'ALTER TABLE images ADD COLUMN ocr_text TEXT');
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

  /// 监听每个文件夹的已匹配图片数量，返回 Map<folderId, count>
  Stream<Map<String, int>> watchFolderImageCounts() {
    final countExp = imageFolderMap.imageId.count();
    final query = selectOnly(imageFolderMap)
      ..addColumns([imageFolderMap.folderId, countExp]);
    query.groupBy([imageFolderMap.folderId]);
    return query.map((row) {
      return MapEntry(
        row.read(imageFolderMap.folderId)!,
        row.read(countExp)!,
      );
    }).watch().map((rows) => Map.fromEntries(rows));
  }

  /// 监听指定文件夹内的全部图片列表（用于文件夹详情页）
  Stream<List<Image>> watchImagesInFolder(String folderId) {
    final query = select(images).join([
      innerJoin(
        imageFolderMap,
        imageFolderMap.imageId.equalsExp(images.id),
      ),
    ])
      ..where(imageFolderMap.folderId.equals(folderId))
      ..orderBy([OrderingTerm.desc(images.indexedAt)]);
    return query.map((row) => row.readTable(images)).watch();
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
