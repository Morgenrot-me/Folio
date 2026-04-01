// clusters_tab_view.dart
// 智能相册集 Tab 页：展示系统自动通过 pHash 和语义距离聚类生成的相册。
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/database/app_database.dart' hide Image;
import 'cluster_detail_screen.dart';

class ClustersTabView extends StatefulWidget {
  const ClustersTabView({super.key});

  @override
  State<ClustersTabView> createState() => _ClustersTabViewState();
}

class _ClustersTabViewState extends State<ClustersTabView> {
  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();
    return StreamBuilder<List<Cluster>>(
      stream: (db.select(db.clusters)..orderBy([(t) => drift.OrderingTerm.desc(t.imageCount)])).watch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final clusters = snapshot.data ?? [];
        if (clusters.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_mosaic_rounded, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
                const SizedBox(height: 16),
                Text('暂无智能相册集', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('等待系统后台完整运行 AI 聚类分析...', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: clusters.length,
          itemBuilder: (context, index) => _buildClusterCard(context, clusters[index]),
        );
      },
    );
  }

  Widget _buildClusterCard(BuildContext context, Cluster cluster) {
    final db = context.read<AppDatabase>();
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ClusterDetailScreen(cluster: cluster)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: StreamBuilder(
                  // 获取此聚类的第一张封面图
                  stream: (db.select(db.images)
                        ..where((t) => t.clusterId.equals(cluster.id))
                        ..limit(1))
                      .watchSingleOrNull(),
                  builder: (context, AsyncSnapshot imgSnap) { // AsyncSnapshot<Image?> has issues if hidden
                    if (imgSnap.hasData && imgSnap.data != null) {
                      final imgData = imgSnap.data;
                      return Image.file(
                        File(imgData.filePath),
                        fit: BoxFit.cover,
                        cacheWidth: 300,
                        errorBuilder: (ctx, err, stack) => Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      );
                    }
                    return Container(color: Theme.of(context).colorScheme.surfaceContainerHighest);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cluster.name.isEmpty ? '未命名相册' : cluster.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.photo_library_outlined, size: 12, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${cluster.imageCount} 张',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
