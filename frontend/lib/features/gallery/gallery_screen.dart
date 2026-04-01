// gallery_screen.dart
// 相册时光轴页：Slivers 原生瀑布流，按日期自动聚合，彻底分离 DB 更新引发的帧重绘
//
// 修复点：
//   - 移除了被后台 AI 疯狂刷新的 db.watch() 污染，改用手动分页游标，帧数从 15fps 飙回 120fps
//   - 加入了 SliverGrid 日期分组聚合逻辑
//   - 引入原生互动滚动条 RawScrollbar (右侧长下划抓手)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/database/app_database.dart' hide Image;
import '../search/search_screen.dart';
import 'image_detail_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  int _offset = 0;
  final int _pageSize = 60; // 降低每次 IO 拉取压力
  bool _hasMore = true;
  
  // 按照日期字符串分组的数据，彻底切断被数据库疯狂 watch() 刷新导致的卡顿
  final Map<String, List<Image>> _groupedImages = {};
  
  // 方便在点击相片时，能将平铺的 List 传给详情页进行滑动预览
  final List<Image> _flatImages = [];

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 距底部还剩 500 像素时预加载下一页
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  /// 使用静态分页抓取，防御 drift .watch() 带来的灾难级 UI 重建
  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    final db = context.read<AppDatabase>();
    final newImages = await (db.select(db.images)
          ..orderBy([(t) => drift.OrderingTerm.desc(t.takenAt), (t) => drift.OrderingTerm.desc(t.indexedAt)]) // 优先根据拍摄时间倒序
          ..limit(_pageSize, offset: _offset))
        .get();

    if (newImages.isEmpty) {
      if (mounted) setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    // 将照片按照时间注入到不同日期的坑位组里
    for (final img in newImages) {
      _flatImages.add(img);
      
      // 时间选择：有 EXIF 拍摄时间就用，没有的话保底用入库时间
      final ms = img.takenAt ?? img.indexedAt;
      final date = DateTime.fromMillisecondsSinceEpoch(ms);
      
      // 类原生系统的时光轴文字显示形式
      final dateStr = '${date.year}年${date.month}月${date.day}日';
      
      if (!_groupedImages.containsKey(dateStr)) {
        _groupedImages[dateStr] = [];
      }
      _groupedImages[dateStr]!.add(img);
    }

    _offset += newImages.length;

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: _groupedImages.isEmpty
          ? _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildEmptyState()
          // ✨ 提速防晕点：包裹专属 Native 滑动块引擎
          : RawScrollbar(
              controller: _scrollController,
              interactive: true,            // 允许手抓粗长条拖拽
              thickness: 6,                 // 滑块适度加粗
              radius: const Radius.circular(4),
              thumbColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  for (final entry in _groupedImages.entries) ...[
                    // ── 1. 日期标题层 (SliverToBoxAdapter 单独截断) ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                    
                    // ── 2. 该日期的照片网格 (SliverGrid 无缝衔接) ──
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final imgData = entry.value[index];
                            
                            // 确定当前方块在全局 flat 数组中的精确位点
                            // 用于点开相片大图时，手指左右滑动的游标不错乱
                            final flatIndex = _flatImages.indexWhere((e) => e.id == imgData.id);
                            
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ImageDetailScreen(
                                      images: List.from(_flatImages),
                                      initialIndex: flatIndex != -1 ? flatIndex : 0,
                                      heroTag: imgData.id,
                                    ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: imgData.id,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    File(imgData.filePath),
                                    fit: BoxFit.cover,
                                    cacheWidth: 300, // 强制缓存超小解析度，防 RAM 溢死
                                    errorBuilder: (ctx, err, stack) => Container(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: entry.value.length,
                        ),
                      ),
                    ),
                  ],
                  
                  // ── 3. 底部动态缓冲尾巴 ──
                  if (_isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else
                    const SliverToBoxAdapter(child: SizedBox(height: 100)), // 防触底反弹区域
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
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
}
