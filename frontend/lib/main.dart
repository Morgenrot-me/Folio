// main.dart
// 应用入口：初始化数据库和服务实例（懒加载模型），通过 Provider 注入全局。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/root/root_screen.dart';
import 'core/database/app_database.dart';
import 'core/services/feature_extractor_service.dart';
import 'core/services/media_scanner_service.dart';
import 'core/services/smart_folder_matcher_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final featureExtractor = FeatureExtractorService(database);
  final matcher = SmartFolderMatcherService(database);
  // MediaScannerService 现在依赖 matcher，扫描完成后自动触发规则匹配
  final scannerService = MediaScannerService(database, featureExtractor, matcher);

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        Provider<FeatureExtractorService>.value(value: featureExtractor),
        Provider<SmartFolderMatcherService>.value(value: matcher),
        Provider<MediaScannerService>.value(value: scannerService),
      ],
      child: const SmartGalleryApp(),
    ),
  );
}

class SmartGalleryApp extends StatelessWidget {
  const SmartGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '智能图库',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const RootScreen(),
    );
  }
}
