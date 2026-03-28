// image_detail_screen.dart
// 全屏沉浸式看图页，接近原生相册体验。
// 功能：
//   - PageView 左右滑动切换图片，信息面板内容随之同步
//   - InteractiveViewer 捏合缩放（最大 6x），缩小到 1x 以下松手自动回弹
//   - 点击图片切换顶部/底部栏显示（信息面板固定时不受影响）
//   - 右上角 ⓘ 按钮弹出磨砂玻璃信息面板，📌 固定后常驻

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/database/app_database.dart' as db;
import '../../core/services/feature_extractor_service.dart';

class ImageDetailScreen extends StatefulWidget {
  final List<db.Image> images;
  final int initialIndex;
  /// 调用方传入的 hero tag（仅初始图片使用）
  final Object? heroTag;

  const ImageDetailScreen({
    super.key,
    required this.images,
    required this.initialIndex,
    this.heroTag,
  });

  @override
  State<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;

  bool _showChrome = true;
  bool _showInfo = false;
  bool _isPinned = false;
  bool _isAnalyzingCurrent = false; // 当前图片是否正在前台 AI 分析中

  late AnimationController _panelController;
  late Animation<Offset> _panelSlide;

  db.Image get _currentImage => widget.images[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top]);

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic));

    // 进入详情页时，若当前图片尚未 AI 分析，立即触发
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAnalysisIfNeeded(_currentImage);
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _panelController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    // 翻到新图片时，若未分析则立即触发
    _triggerAnalysisIfNeeded(widget.images[index]);
  }

  /// 若图片尚未 AI 分析，立即在前台触发（不等 WorkManager）
  Future<void> _triggerAnalysisIfNeeded(db.Image image) async {
    if (image.isAnalyzed) return;
    if (_isAnalyzingCurrent) return;
    if (!mounted) return;

    setState(() => _isAnalyzingCurrent = true);
    try {
      final extractor = context.read<FeatureExtractorService>();
      await extractor.extractFeaturesForImage(image.id, image.filePath);
    } catch (e) {
      debugPrint('[Detail] 按需分析失败: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzingCurrent = false);
    }
  }

  void _handleMainTap() {
    if (_showInfo && !_isPinned) {
      // 未固定时点击关闭信息面板
      _closePanel();
    } else {
      // 切换顶底栏的可见性
      setState(() => _showChrome = !_showChrome);
    }
  }

  void _toggleInfo() {
    setState(() => _showInfo = !_showInfo);
    if (_showInfo) {
      _panelController.forward();
      setState(() => _showChrome = true); // 显示信息时确保顶栏可见
    } else {
      _isPinned = false;
      _panelController.reverse();
    }
  }

  void _closePanel() {
    setState(() {
      _showInfo = false;
      _isPinned = false;
    });
    _panelController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. PageView：左右滑动切换 ──────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (ctx, index) {
              final image = widget.images[index];
              final isFirst = index == widget.initialIndex;
              return _ImageViewPage(
                image: image,
                heroTag: (isFirst && widget.heroTag != null) ? widget.heroTag : null,
              );
            },
          ),

          // ── 2. 透明单击监听层（不阻止 PageView drag 和 InteractiveViewer scale）
          // behavior: translucent 确保此层不绿断手势，仅 TapGestureRecognizer 参与竞争。
          // 竞争规则：单击(无移动) → TapRecognizer 赢；左右滑(水平移动) → PageView 赢；捆合 → InteractiveViewer 赢
          Positioned.fill(
            child: GestureDetector(
              onTap: _handleMainTap,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),

          // ── 3. 顶部渐变栏（Positioned 定位到顶部，不再被 StackFit.expand 拉满全屏） ────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_showChrome,
              child: AnimatedOpacity(
                opacity: _showChrome ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xCC000000), // ~80% 黑
                        Color(0x44000000), // ~27%
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false, // 顶部栏不需要底部安全边距
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _currentImage.fileName,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                // AI 分析中角标
                                if (_isAnalyzingCurrent) ...[
                                  const SizedBox(width: 6),
                                  const SizedBox(
                                    width: 13, height: 13,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('AI 分析中',
                                      style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11)),
                                ],
                              ],
                            ),
                          ),
                          if (widget.images.length > 1)
                            Text(
                              '${_currentIndex + 1} / ${widget.images.length}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 13),
                            ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _showInfo
                                    ? Icons.info_rounded
                                    : Icons.info_outline_rounded,
                                key: ValueKey(_showInfo),
                                color: _showInfo ? Colors.white : Colors.white70,
                              ),
                            ),
                            tooltip: '图片信息',
                            onPressed: _toggleInfo,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 4. 底部信息面板（磁玉玻璃，可固定） ──────────────────────
          if (_showInfo)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _panelSlide,
                child: _buildInfoPanel(context),
              ),
            ),
        ],
      ),
    );
  }

  // ── 信息面板 ──────────────────────────────────────────────────────────────

  Widget _buildInfoPanel(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // 阻止点击穿透到主区域
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: Colors.black.withValues(alpha: 0.58),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖拽条 + 操作按钮
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _isPinned = !_isPinned),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Icon(
                          _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                          color: _isPinned ? Colors.white : Colors.white38,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _closePanel,
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white38, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._buildInfoRows(_currentImage),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildInfoRows(db.Image image) {
    final rows = <_InfoItem>[];

    if (image.takenAt != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(image.takenAt!);
      rows.add(_InfoItem(
        icon: Icons.calendar_today_rounded,
        label: '拍摄时间',
        value: '${dt.year}年${dt.month}月${dt.day}日  '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
      ));
    }

    rows.add(_InfoItem(
      icon: Icons.photo_size_select_actual_rounded,
      label: '尺寸',
      value:
          '${image.width} × ${image.height}  ·  ${(image.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
    ));

    if (image.isAnalyzed) {
      rows.add(_InfoItem(
        icon: Icons.lens_blur_rounded,
        label: '清晰度',
        value: _blurLabel(image.blurScore),
      ));
    }

    final badges = <String>[];
    if (image.isScreenshot) badges.add('📱 截图');
    if (image.hasText) badges.add('📝 含文字');
    if (badges.isNotEmpty) {
      rows.add(_InfoItem(
        icon: Icons.label_outline_rounded,
        label: '属性',
        value: badges.join('  '),
      ));
    }

    if (image.isAnalyzed) {
      rows.add(_InfoItem(
        icon: Icons.thermostat_rounded,
        label: '色温',
        value: _warmthLabel(image.colorWarmth),
      ));
    }

    if (image.tags != null && image.tags!.isNotEmpty) {
      final tagList =
          image.tags!.split(',').take(3).map((t) => t.trim()).join('  ·  ');
      rows.add(_InfoItem(
        icon: Icons.auto_awesome_rounded,
        label: 'AI 识别',
        value: tagList,
      ));
    }

    return rows.map((item) => _buildRow(item)).toList();
  }

  Widget _buildRow(_InfoItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 18, color: Colors.white60),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(item.value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _blurLabel(double score) {
    if (score >= 500) return '非常清晰';
    if (score >= 200) return '清晰';
    if (score >= 80) return '较清晰';
    if (score >= 30) return '轻微模糊';
    return '模糊';
  }

  String _warmthLabel(double warmth) {
    if (warmth > 0.3) return '暖调（红 / 橙 / 黄）';
    if (warmth > 0.1) return '偏暖';
    if (warmth < -0.3) return '冷调（蓝 / 青）';
    if (warmth < -0.1) return '偏冷';
    return '中性';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 单张图片页：InteractiveViewer + 缩小回弹逻辑
// ─────────────────────────────────────────────────────────────────────────────
class _ImageViewPage extends StatefulWidget {
  final db.Image image;
  final Object? heroTag;

  const _ImageViewPage({
    required this.image,
    this.heroTag,
  });

  @override
  State<_ImageViewPage> createState() => _ImageViewPageState();
}

class _ImageViewPageState extends State<_ImageViewPage>
    with SingleTickerProviderStateMixin {
  final _transformController = TransformationController();
  late AnimationController _snapController;
  Animation<Matrix4>? _snapAnimation;

  /// 实时监听缩放比例，动态控制 panEnabled。
  /// scale ≤ 1.01 → panEnabled=false，PageView 接管水平翻页手势
  /// scale >  1.01 → panEnabled=true，InteractiveViewer 接管图内平移
  bool _panEnabled = false;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        if (_snapAnimation != null) {
          _transformController.value = _snapAnimation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  /// 实时监听缩放比例，动态切换 panEnabled
  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final shouldPan = scale > 1.01;
    if (shouldPan != _panEnabled) {
      setState(() => _panEnabled = shouldPan);
    }
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if (scale < 1.0) {
      _snapAnimation = Matrix4Tween(
        begin: _transformController.value,
        end: Matrix4.identity(),
      ).animate(
          CurvedAnimation(parent: _snapController, curve: Curves.easeOutBack));
      _snapController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image.file(
      File(widget.image.filePath),
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const Center(
            child: CircularProgressIndicator(color: Colors.white));
      },
      errorBuilder: (ctx, err, stack) => const Center(
        child: Icon(Icons.broken_image_outlined,
            size: 72, color: Colors.white30),
      ),
    );

    if (widget.heroTag != null) {
      imageWidget = Hero(tag: widget.heroTag!, child: imageWidget);
    }

    // 单击由 Stack 的 translucent 遮罩层处理，此处直接返回 InteractiveViewer
    return InteractiveViewer(
      transformationController: _transformController,
      onInteractionEnd: _onInteractionEnd,
      panEnabled: _panEnabled,
      minScale: 0.5,
      maxScale: 6.0,
      child: imageWidget,
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({required this.icon, required this.label, required this.value});
}
