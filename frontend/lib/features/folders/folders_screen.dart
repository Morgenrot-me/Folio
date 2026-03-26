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
      appBar: AppBar(
        title: const Text('智能分类'),
      ),
      body: StreamBuilder<List<SmartFolder>>(
        stream: database.select(database.smartFolders).watch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final folders = snapshot.data ?? [];
          if (folders.isEmpty) {
            return _buildEmptyState(context);
          }
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              return _buildFolderCard(context, folders[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateFolderScreen()));
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          Text(
            '这里空空如也',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角，立刻创立你的第一个虚拟智能筛选规则',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderCard(BuildContext context, SmartFolder folder) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_shared_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Icon(Icons.more_horiz_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
