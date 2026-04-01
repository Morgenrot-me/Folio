// gallery_screen.dart
// 相册时光轴页：所有已索引图片，分页加载防 OOM。
// 修复：
//   - _onScroll 添加防抖（已满才扩展，避免无限 setState）
//   - heroTag 传入 ImageDetailScreen
//   - 空状态文案友好化，提供快捷跳转提示

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/database/app_database.dart' hide Image;
import '../search/search_screen.dart';
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
  int _lastDataLength = 0; // 防抖：记录上次数据量，仅在数据填满时才扩展

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

  /// 防抖：仅当当前数据已全部渲染（== _loadedCount）时才扩展 limit，
  /// 避免用户停在底部时每次微滚动都触发 setState
  void _onScroll() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 300) return;
    if (_lastDataLength >= _loadedCount) {
      setState(() => _loadedCount += _kGalleryPageSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('相册时光轴'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(Icons.image_search_rounded, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      '搜索地点、场景、物体...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
          _lastDataLength = images.length; // 更新防抖基准

          if (images.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 72,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '暂无照片',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '请前往「大盘总览」→「特征扫描提取」开始索引',
                      textAlign: TextAlign.center,
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
                      builder: (_) => ImageDetailScreen(
                        images: List.from(images),
                        initialIndex: index,
                        heroTag: imgData.id,
                      ),
                    ),
                  );
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
