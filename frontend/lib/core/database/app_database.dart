import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
  int get schemaVersion => 1;

  // 监听所有被索引的图片张数，形成动态流
  Stream<int> watchTotalImagesCount() {
    final countExp = images.id.count();
    final query = selectOnly(images)..addColumns([countExp]);
    return query.map((row) => row.read(countExp)!).watchSingle();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'smart_gallery.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
