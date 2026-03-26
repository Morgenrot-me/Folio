// home_screen.dart
// 主页大盘：统计数、进度条、快捷操作、近期索引缩略图。
// 修复：
//   - StatefulWidget 持有 _isScanning 状态，扫描期间按钮禁用并显示加载指示
//   - 蓝→紫渐变替代原来的纯色透明退化渐变
//   - withOpacity → withValues

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/database/app_database.dart' hide Image;
import '../../core/services/media_scanner_service.dart';
import '../../core/services/smart_folder_matcher_service.dart';
import '../gallery/image_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isScanning = false;
  bool _isMatching = false;

  @override
  Widget build(BuildContext context) {
    final database = context.read<AppDatabase>();

    return Scaffold(
      appBar: AppBar(title: const Text('大盘概览')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _buildHeroCard(context),
          const SizedBox(height: 24),
          Text(
            '快捷操作',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionCard(
                context,
                icon: _isScanning ? Icons.hourglass_top_rounded : Icons.sync_rounded,
                label: _isScanning ? '扫描中...' : '特征扫描提取',
                enabled: !_isScanning && !_isMatching,
                onTap: _handleScan,
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                context,
                icon: _isMatching ? Icons.hourglass_top_rounded : Icons.auto_awesome_rounded,
                label: _isMatching ? '匹配中...' : '执行规则匹配',
                enabled: !_isScanning && !_isMatching,
                onTap: _handleMatch,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '近期已索引特征照片',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: (database.select(database.images)
                  ..orderBy([(t) => drift.OrderingTerm.desc(t.indexedAt)])
                  ..limit(6))
                .watch(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final images = snapshot.data ?? [];
              if (images.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      '暂无近期入库记录',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
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
                            imageRow: imgData,
                            heroTag: 'home_${imgData.id}', // 统一 hero tag
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'home_${imgData.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
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
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final database = context.read<AppDatabase>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // 主色蓝深浅渐变，清爽统一
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '本地图像智能索引数量',
            style: TextStyle(
                color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          StreamBuilder<int>(
            stream: database.watchTotalImagesCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Text(
                '$count 张',
                style: const TextStyle(
                    color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
              );
            },
          ),
          const SizedBox(height: 20),
          StreamBuilder<int>(
            stream: database.watchTotalImagesCount(),
            builder: (context, totalSnap) {
              final total = totalSnap.data ?? 0;
              return StreamBuilder<int>(
                stream: database.watchAnalyzedImagesCount(),
                builder: (context, analyzedSnap) {
                  final analyzed = analyzedSnap.data ?? 0;
                  final progress = total > 0 ? analyzed / total : 0.0;
                  final pct = total > 0 ? (progress * 100).toStringAsFixed(0) : '—';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        total > 0
                            ? 'AI 分析完成 $analyzed / $total 张（$pct%）'
                            : '尚未扫描，点击"特征扫描提取"开始',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Expanded(
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
      ),
    );
  }

  Future<void> _handleScan() async {
    if (_isScanning || _isMatching) return;
    setState(() => _isScanning = true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已启动本地相册特征扫描...')),
    );

    try {
      final scanner = context.read<MediaScannerService>();
      final newCount = await scanner.scanAndIndexNewImages();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 扫描完成，新增 $newCount 张！已自动触发规则匹配')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('扫描失败，请检查相册权限: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  /// 手动触发规则匹配（不重新扫描）
  Future<void> _handleMatch() async {
    if (_isScanning || _isMatching) return;
    setState(() => _isMatching = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在执行规则匹配...')),
    );
    try {
      final matcher = context.read<SmartFolderMatcherService>();
      final matched = await matcher.runMatchForAll();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 规则匹配完成，共归类 $matched 张图片')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('匹配失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isMatching = false);
    }
  }
}
