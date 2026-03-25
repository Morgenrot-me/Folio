import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../folders/folders_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = const [
    HomeScreen(),
    FoldersScreen(),
    Center(child: Text("应用设置", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: '大盘总览',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_special_rounded),
                label: '智能分类',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
                label: '设置',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
