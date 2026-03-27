// main.dart
// 应用入口：初始化数据库、服务实例（懒加载模型）和 WorkManager 后台调度器。
// 通过 Provider 注入全局依赖。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/root/root_screen.dart';
import 'core/database/app_database.dart';
import 'core/services/feature_extractor_service.dart';
import 'core/services/media_scanner_service.dart';
import 'core/services/smart_folder_matcher_service.dart';
import 'core/services/background_ai_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. 初始化 WorkManager（必须在 runApp 之前，且在 ensureInitialized 之后）
  await BackgroundAiWorker.initialize();

  // ── 2. 初始化前台服务
  final database = AppDatabase();
  final featureExtractor = FeatureExtractorService(database);
  final matcher = SmartFolderMatcherService(database);
  final scannerService = MediaScannerService(database, featureExtractor, matcher);

  // ── 3. 断点续传：App 启动时检查是否有未分析图片，若有则自动调度后台任务
  //   场景：用户上次扫描中途关闭 App、手机重启等情况均能自动恢复
  final unanalyzedCount = await (database.select(database.images)
        ..where((t) => t.isAnalyzed.equals(false)))
      .get()
      .then((r) => r.length);

  if (unanalyzedCount > 0) {
    debugPrint('main: 发现 $unanalyzedCount 张未分析图片，自动调度后台 AI 任务');
    await BackgroundAiWorker.schedule();
  }

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
