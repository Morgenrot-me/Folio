// root_screen.dart
// 根页面：使用 NavigationBar（Material 3）+ IndexedStack。
// IndexedStack 保留各 Tab 状态（不在切换时重建），页面切换无动画跳跃感。
// 每个子页面自带 Scaffold（AppBar 各自独立），RootScreen 本身不再嵌套 Scaffold body。
// v2: 新增「语义搜索」Tab，使用 MobileCLIP 文本编码器实现自然语言图片检索。

import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../gallery/gallery_screen.dart';
import '../folders/folders_screen.dart';
import '../settings/settings_screen.dart';

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
    SettingsScreen(),
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
            label: '相册',
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
