import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/root/root_screen.dart';
import 'core/database/app_database.dart';
import 'core/services/feature_extractor_service.dart';
import 'core/services/media_scanner_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据库（轻量，立即返回）
  final database = AppDatabase();

  // 创建服务实例，不在启动时加载模型（懒加载：首次扫描时自动触发）
  final featureExtractor = FeatureExtractorService(database);
  final scannerService = MediaScannerService(database, featureExtractor);

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        Provider<FeatureExtractorService>.value(value: featureExtractor),
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
      themeMode: ThemeMode.system, // 支持系统自动深色模式切换
      debugShowCheckedModeBanner: false,
      home: const RootScreen(),
    );
  }
}
