import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/app_database.dart';
import '../../core/services/media_scanner_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _buildHeroCard(context),
          const SizedBox(height: 24),
          Text(
            '快捷操作 (Quick Actions)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionCard(
                context, 
                Icons.sync_rounded, 
                '特征扫描提取',
                onTap: () => _handleScan(context),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                context, 
                Icons.auto_awesome_rounded, 
                '聚类归置',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '近期流转视图',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 16),
          // 骨架屏演示近期图片坑位
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.image_outlined, color: Colors.grey, size: 28),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final database = context.read<AppDatabase>();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withBlue(255),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '本地图像智能索引数量',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          StreamBuilder<int>(
            stream: database.watchTotalImagesCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Text(
                '$count 张',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  child: LinearProgressIndicator(
                    value: 0.0, // 初始阶段暂时预置为 0，后期依据相机图库总数计算
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                '0%',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String label, {required VoidCallback onTap}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleScan(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已启动本地相册特征扫描，这可能需要一会儿的时间...')),
    );
    try {
      final scanner = context.read<MediaScannerService>();
      await scanner.scanAndIndexNewImages();
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 本次智能索引增量比对已完成入库！')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('扫描时发生错误，请检查是否有相册读取权限或看日志: $e')),
        );
      }
    }
  }
}
