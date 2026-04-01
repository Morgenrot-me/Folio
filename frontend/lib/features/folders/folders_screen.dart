// folders_screen.dart
// 智能分类文件夹页：展示所有智能过滤文件夹，支持重匹配触发、图片数量显示、重命名、删除等操作。
// 改善：
//   - 文件夹卡片实时显示已匹配图片数量（来自 watchFolderImageCounts()）
//   - AppBar 添加"重新匹配"按钮，手动触发 SmartFolderMatcherService
//   - 文件夹重命名：弹出 TextField 对话框，直接更新数据库

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/database/app_database.dart' hide Image;
import '../../core/services/smart_folder_matcher_service.dart';
import '../../core/services/cluster_service.dart';
import '../../core/services/media_scanner_service.dart';
import 'create_folder_screen.dart';
import 'folder_detail_screen.dart';
import 'clusters_tab_view.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  bool _isMatching = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('智能分类'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '规则分类'),
              Tab(text: '智能相册集'),
            ],
          ),
          actions: [
            Builder(builder: (ctx) {
              final tabController = DefaultTabController.of(ctx);
              return AnimatedBuilder(
                animation: tabController,
                builder: (context, child) {
                  return _isMatching
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: tabController.index == 0 ? '重新匹配规则' : '运行 AI 聚类',
                          onPressed: () => _handleReMatch(tabController.index),
                        );
                },
              );
            }),
          ],
        ),
        body: TabBarView(
          children: [
            _buildRulesTab(),
            const ClustersTabView(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (ctx) {
            final tabController = DefaultTabController.of(ctx);
            return AnimatedBuilder(
              animation: tabController,
              builder: (context, child) {
                if (tabController.index == 0) {
                  return FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const CreateFolderScreen()));
                    },
                    icon: const Icon(Icons.create_new_folder_rounded),
                    label: const Text('新建分类'),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRulesTab() {
    final database = context.read<AppDatabase>();
    return StreamBuilder<List<SmartFolder>>(
      stream: database.select(database.smartFolders).watch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final folders = snapshot.data ?? [];
        if (folders.isEmpty) return _buildEmptyState(context);

        return StreamBuilder<Map<String, int>>(
          stream: database.watchFolderImageCounts(),
          builder: (context, countSnap) {
            final counts = countSnap.data ?? {};
            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.05,
              ),
              itemCount: folders.length,
              itemBuilder: (context, index) => _buildFolderCard(
                context,
                folders[index],
                counts[folders[index].id] ?? 0,
              ),
            );
          },
        );
      },
    );
  }

  /// 触发全量规则重匹配或自动聚类
  Future<void> _handleReMatch(int tabIndex) async {
    if (_isMatching) return;
    setState(() => _isMatching = true);

    final isRules = tabIndex == 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isRules ? '正在重新执行规则匹配...' : '正在执行全量 AI 聚类分析... (可能需要几秒到一分钟)')),
    );
    try {
      int matched = 0;
      if (isRules) {
        final matcher = context.read<SmartFolderMatcherService>();
        matched = await matcher.runMatchForAll();
      } else {
        final clusterSvc = context.read<ClusterService>();
        matched = await clusterSvc.runClustering();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 处理完成，共生成/匹配 $matched 个${isRules ? "张图片" : "相册聚类"}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isMatching = false);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            '这里空空如也',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮，创建你的第一个智能筛选规则',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderCard(BuildContext context, SmartFolder folder, int imageCount) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        child: InkWell(
          // 跳转文件夹详情页
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FolderDetailScreen(folder: folder),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.folder_shared_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showFolderMenu(context, folder),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  folder.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 显示已匹配图片数量
                Row(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$imageCount 张',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        folder.rootRuleId != null ? '已配置规则' : '待配置规则',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFolderMenu(BuildContext context, SmartFolder folder) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline_rounded),
              title: const Text('重命名'),
              onTap: () {
                Navigator.pop(ctx);
                _renameFolder(context, folder);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded,
                  color: Theme.of(ctx).colorScheme.error),
              title: Text('删除',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, folder);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 弹出对话框编辑文件夹名称并写库
  void _renameFolder(BuildContext context, SmartFolder folder) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入新名称',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _doRename(context, ctx, folder, controller),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => _doRename(context, ctx, folder, controller),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  Future<void> _doRename(
    BuildContext pageContext,
    BuildContext dialogContext,
    SmartFolder folder,
    TextEditingController controller,
  ) async {
    final newName = controller.text.trim();
    if (newName.isEmpty) return;
    Navigator.pop(dialogContext);
    final db = pageContext.read<AppDatabase>();
    await (db.update(db.smartFolders)..where((t) => t.id.equals(folder.id)))
        .write(SmartFoldersCompanion(name: Value(newName)));
    if (pageContext.mounted) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
        SnackBar(content: Text('已重命名为「$newName」')),
      );
    }
  }

  void _confirmDelete(BuildContext context, SmartFolder folder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('将永久删除「${folder.name}」及其所有规则，无法恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final db = context.read<AppDatabase>();
              await (db.delete(db.smartFolders)
                    ..where((t) => t.id.equals(folder.id)))
                  .go();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已删除「${folder.name}」')),
                );
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
