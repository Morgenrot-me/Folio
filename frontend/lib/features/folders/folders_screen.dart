// folders_screen.dart
// 智能分类文件夹页：展示所有智能过滤文件夹，支持点击查看详情和长按/三点菜单操作。
// 修复：
//   - 文件夹卡片添加 InkWell（涟漪 + 点击）
//   - 三点菜单绑定底部操作表（重命名占位 + 删除确认）
//   - 所有 withOpacity → withValues

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/app_database.dart';
import 'create_folder_screen.dart';

class FoldersScreen extends StatelessWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final database = context.read<AppDatabase>();

    return Scaffold(
      appBar: AppBar(title: const Text('智能分类')),
      body: StreamBuilder<List<SmartFolder>>(
        stream: database.select(database.smartFolders).watch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final folders = snapshot.data ?? [];
          if (folders.isEmpty) return _buildEmptyState(context);

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: folders.length,
            itemBuilder: (context, index) =>
                _buildFolderCard(context, folders[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const CreateFolderScreen()));
        },
        icon: const Icon(Icons.create_new_folder_rounded),
        label: const Text('新建分类'),
      ),
    );
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

  Widget _buildFolderCard(BuildContext context, SmartFolder folder) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        child: InkWell(
          // 点击：跳转文件夹详情（功能待实现时显示提示）
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('「${folder.name}」文件夹详情开发中')),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
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
                    // 三点菜单：绑定底部操作表
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
                Text(
                  folder.rootRuleId != null ? '已挂载节点规则' : '等待添加分类规则',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 文件夹操作底部菜单
  void _showFolderMenu(BuildContext context, SmartFolder folder) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('重命名功能开发中')),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  '删除',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, folder);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// 删除确认对话框
  void _confirmDelete(BuildContext context, SmartFolder folder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('将永久删除「${folder.name}」及其所有规则，无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
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
