// cluster_detail_screen.dart
// 智能相册集详情页：展示相册内的所有图片，并支持重命名或解散相册。
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/database/app_database.dart' hide Image;
import '../gallery/image_detail_screen.dart';

class ClusterDetailScreen extends StatefulWidget {
  final Cluster cluster;
  const ClusterDetailScreen({super.key, required this.cluster});

  @override
  State<ClusterDetailScreen> createState() => _ClusterDetailScreenState();
}

class _ClusterDetailScreenState extends State<ClusterDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();
    final title = widget.cluster.name.isEmpty ? '智能相册集' : widget.cluster.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: '重命名',
            onPressed: () => _renameCluster(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: '解散相册集',
            onPressed: () => _deleteCluster(context),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: (db.select(db.images)
              ..where((t) => t.clusterId.equals(widget.cluster.id))
              ..orderBy([(t) => drift.OrderingTerm.desc(t.indexedAt)]))
            .watch(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final images = snapshot.data ?? [];
          if (images.isEmpty) {
            return const Center(child: Text('此相册为空', style: TextStyle(color: Colors.grey)));
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
              final tag = 'cluster_${widget.cluster.id}_${imgData.id}';
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageDetailScreen(
                        images: List.from(images),
                        initialIndex: index,
                        heroTag: tag,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: tag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(imgData.filePath),
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                      errorBuilder: (ctx, err, stack) =>
                          Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
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

  void _renameCluster(BuildContext context) {
    final controller = TextEditingController(text: widget.cluster.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入新名称', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              Navigator.pop(ctx);
              final db = context.read<AppDatabase>();
              await (db.update(db.clusters)..where((t) => t.id.equals(widget.cluster.id)))
                  .write(ClustersCompanion(name: drift.Value(newName), isUserNamed: const drift.Value(true)));
              if (mounted) setState(() {});
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _deleteCluster(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('解散相册集'),
        content: const Text('解散后，相册集将消失，但相片本身不会被删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final db = context.read<AppDatabase>();
              // 解除绑定的 clusterId
              await (db.update(db.images)..where((t) => t.clusterId.equals(widget.cluster.id)))
                  .write(const ImagesCompanion(clusterId: drift.Value(null)));
              await (db.delete(db.clusters)..where((t) => t.id.equals(widget.cluster.id))).go();
              if (mounted) Navigator.pop(context); // 退出详情页
            },
            child: const Text('解散'),
          ),
        ],
      ),
    );
  }
}
