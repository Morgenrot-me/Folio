import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/root/root_screen.dart';
import 'core/database/app_database.dart';
import 'core/services/feature_extractor_service.dart';
import 'core/services/media_scanner_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化全局数据库
  final database = AppDatabase();
  
  // 实例化大模型分析管线并提前把 300MB 的模型权重全家桶装载进内存
  final featureExtractor = FeatureExtractorService(database);
  await featureExtractor.initModel();

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
