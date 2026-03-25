import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/root/root_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartGalleryApp());
}

class SmartGalleryApp extends StatelessWidget {
  const SmartGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Gallery',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // 支持系统自动深色模式切换
      debugShowCheckedModeBanner: false,
      home: const RootScreen(),
    );
  }
}
