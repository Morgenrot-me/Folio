// folder_detail_screen.dart
// 文件夹详情页：展示智能文件夹下所有匹配图片的网格缩略图。

import 'dart:io';
import 'package:flutter/material.dart'; // Flutter Image widget 正常使用
import 'package:provider/provider.dart';
import '../../core/database/app_database.dart' as db; // Drift 类型加 db. 前缀
import '../gallery/image_detail_screen.dart';

class FolderDetailScreen extends StatelessWidget {
  final db.SmartFolder folder;

  const FolderDetailScreen({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    final database = context.read<db.AppDatabase>();

    return Scaffold(
      appBar: AppBar(title: Text(folder.name)),
      body: StreamBuilder<List<db.Image>>(
        stream: database.watchImagesInFolder(folder.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final images = snapshot.data ?? [];
          if (images.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_search_rounded,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无匹配图片',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '扫描后系统会自动匹配，或在「智能分类」页点击刷新按钮手动触发',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imgData = images[index];
              final tag = 'folder_${folder.id}_${imgData.id}';
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageDetailScreen(
                        imageRow: imgData,
                        heroTag: tag,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: tag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file( // Flutter Image widget
                      File(imgData.filePath),
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                      errorBuilder: (ctx, err, stack) => Container(
                          color: Theme.of(ctx)
                              .colorScheme
                              .surfaceContainerHighest),
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
