// root_screen.dart
// 根页面：使用 NavigationBar（Material 3）+ IndexedStack。
// IndexedStack 保留各 Tab 状态（不在切换时重建），页面切换无动画跳跃感。
// 每个子页面自带 Scaffold（AppBar 各自独立），RootScreen 本身不再嵌套 Scaffold body。

import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../gallery/gallery_screen.dart';
import '../folders/folders_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;

  /// 子页面实例；IndexedStack 保证它们不会因切换而销毁重建
  final List<Widget> _pages = const [
    HomeScreen(),
    GalleryScreen(),
    FoldersScreen(),
    _SettingsPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack：隐藏未选中页面但保持其状态树，无跳屏、无重绘
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: '大盘总览',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library_rounded),
            label: '相册时光轴',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_special_outlined),
            selectedIcon: Icon(Icons.folder_special_rounded),
            label: '智能分类',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

/// 设置页占位：功能暂未开发，展示友好的空状态引导
class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('应用设置')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 20),
            Text(
              '设置中心开发中',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '隐私权限、模型管理、数据清理等功能即将上线。',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
