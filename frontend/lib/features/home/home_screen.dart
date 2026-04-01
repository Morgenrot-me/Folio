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
import '../../core/services/background_ai_worker.dart';
import '../gallery/image_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  bool _isScanning = false;   // Phase 1 入库中
  bool _isMatching = false;   // 手动规则匹配中
  // 注意：Phase 2 AI 分析现在由 WorkManager 后台执行，无需前台持有状态
  //   进度通过 watchAnalyzedImagesCount() Stream 自动更新

  /// 手机相册总张数（扫描开始瞬间由回调填入，固定不变）
  int? _libraryTotal;
  /// Phase 1 已入库张数（每批 100 张更新一次）
  int _scanIndexed = 0;

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
                icon: _isScanning
                    ? Icons.hourglass_top_rounded
                    : Icons.sync_rounded,
                label: _isScanning ? '入库中...' : '特征扫描提取',
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
                            images: List.from(images),
                            initialIndex: index,
                            heroTag: 'home_${imgData.id}',
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
          // ── 标题 ──────────────────────────────────────────────
          const Text(
            '本地相册总计',
            style: TextStyle(
                color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // ── 大数字：手机相册总张数（扫描前后保持稳定）──────────
          // 扫描前：从数据库读已入库数作为占位
          // 扫描中/后：显示从手机相册获取的真实总数（_libraryTotal）
          Builder(builder: (context) {
            if (_libraryTotal != null) {
              // 扫描已启动，显示手机相册真实总量
              return Text(
                '$_libraryTotal 张',
                style: const TextStyle(
                    color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
              );
            }
            // 扫描尚未启动，显示数据库现有数量
            return StreamBuilder<int>(
              stream: database.watchTotalImagesCount(),
              builder: (ctx, snap) => Text(
                '${snap.data ?? 0} 张',
                style: const TextStyle(
                    color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
              ),
            );
          }),

          const SizedBox(height: 20),

          // ── 进度条 ────────────────────────────────────────────
          // ── 进度条 ────────────────────────────────────────────
          if (_isScanning && _libraryTotal != null && _libraryTotal! > 0)
            // Phase 1 进行中：显示入库进度（每100张刷新）
            _buildScanProgress()
          else
            // 空闲或 Phase 2 AI 分析中：均使用 DB Stream 显示 AI 完成比例
            StreamBuilder<int>(
              stream: database.watchTotalImagesCount(),
              builder: (ctx, totalSnap) {
                final total = totalSnap.data ?? 0;
                return StreamBuilder<int>(
                  stream: database.watchAnalyzedImagesCount(),
                  builder: (ctx, analyzedSnap) {
                    final analyzed = analyzedSnap.data ?? 0;
                    final progress = total > 0 ? analyzed / total : 0.0;
                    final pct = total > 0
                        ? (progress * 100).toStringAsFixed(0)
                        : '—';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          total > 0
                              ? 'AI 分析中... $analyzed / $total 张（$pct%）'
                              : 'AI 分析完成 $analyzed / $total 张（$pct%）',
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

  /// Phase 1 入库进度条组件
  Widget _buildScanProgress() {
    final total = _libraryTotal!;
    final indexed = _scanIndexed;
    final progress = total > 0 ? indexed / total : 0.0;
    final pct = (progress * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '快速入库 $indexed / $total 张（$pct%）',
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500),
        ),
      ],
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
    setState(() {
      _isScanning = true;
      _libraryTotal = null;
      _scanIndexed = 0;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在读取相册总数...')),
    );

    try {
      final scanner = context.read<MediaScannerService>();

      // ── Phase 1：快速入库所有元数据 ─────────────────────────────
      final newCount = await scanner.scanAndIndexMetadata(
        onProgress: (indexed, total) {
          if (!mounted) return;
          setState(() {
            _libraryTotal = total;
            _scanIndexed = indexed;
          });
          if (indexed == 0) {
            // 第一次回调：更新 SnackBar 显示总数
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('快速入库中 (共 $total 张)...'),
                duration: const Duration(hours: 1),
              ),
            );
          }
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ 入库完成，新增 $newCount 张！AI 分析已加入后台队列')),
      );

      // ── Phase 2：调度后台系统队列 + 立即强制拉起前台 AI 线程 ───────
      // 1. Android WorkManager 有时会受限于 JobScheduler 策略（如省电模式）排队延迟数十分钟，
      //    这里我们保留它作为 App 被杀后的“系统级兜底”。
      await BackgroundAiWorker.schedule();

      // 2. BUG FIX: 并行且不阻塞地立刻丢给 Dart 的微任务队列去启动前台分析，
      //    这样只要您还看着 App，AI 提取流立刻就会滚滚向前！
      scanner.analyzeUnanalyzedImages();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
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
