// gallery_screen.dart
// 相册时光轴页：展示所有已索引图片，分页加载（每页 100 张）防止大图库 OOM。

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/database/app_database.dart' hide Image;
import 'image_detail_screen.dart';

/// 每页加载的图片数量
const _kGalleryPageSize = 100;

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ScrollController _scrollController = ScrollController();
  int _loadedCount = _kGalleryPageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动到底部时扩展加载数量
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      setState(() => _loadedCount += _kGalleryPageSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('所有相片核心特征库'),
      ),
      body: StreamBuilder(
        stream: (db.select(db.images)
              ..orderBy([(t) => drift.OrderingTerm.desc(t.indexedAt)])
              ..limit(_loadedCount))
            .watch(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final images = snapshot.data ?? [];
          if (images.isEmpty) {
            return const Center(
              child: Text(
                '您还没扫描任何相片，请回大盘点击扫描按钮！',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imgData = images[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ImageDetailScreen(imageRow: imgData)));
                },
                child: Hero(
                  tag: imgData.id,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(imgData.filePath),
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                      errorBuilder: (ctx, err, stack) => Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
