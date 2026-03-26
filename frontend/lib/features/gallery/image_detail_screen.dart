// image_detail_screen.dart
// 图片详情页：全屏沉浸式看图，右上角 ⓘ 按钮弹出磨砂玻璃信息面板。
// 设计原则：「看图」是主要需求，信息是辅助，把技术细节藏起来，只展示用户能理解的内容。

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/database/app_database.dart' as db;

class ImageDetailScreen extends StatefulWidget {
  final db.Image imageRow;
  final Object heroTag;

  const ImageDetailScreen({
    super.key,
    required this.imageRow,
    required this.heroTag,
  });

  @override
  State<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _showInfo = false;
  bool _isPinned = false;

  late final AnimationController _panelController;
  late final Animation<Offset> _panelSlide;

  @override
  void initState() {
    super.initState();
    // 设置全屏沉浸式（隐藏状态栏/导航栏）
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top]);
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _panelController.dispose();
    super.dispose();
  }

  void _toggleInfo() {
    setState(() => _showInfo = !_showInfo);
    if (_showInfo) {
      _panelController.forward();
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
      body: GestureDetector(
        // 点击主区域：未固定时关闭面板；已固定不关
        onTap: () {
          if (_showInfo && !_isPinned) _closePanel();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. 全屏图片（支持捏合缩放和双击放大）────────────────────────
            Hero(
              tag: widget.heroTag,
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 6.0,
                child: Image.file(
                  File(widget.imageRow.filePath),
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
                ),
              ),
            ),

            // ── 2. 顶部渐变栏（返回 + 信息按钮）─────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.imageRow.fileName,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      // ⓘ 信息按钮
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
                        tooltip: 'AI 信息',
                        onPressed: _toggleInfo,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 3. 底部信息面板（磨砂玻璃，可固定）──────────────────────────
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
      ),
    );
  }

  // ── 信息面板 ─────────────────────────────────────────────────────────────

  Widget _buildInfoPanel(BuildContext context) {
    return GestureDetector(
      // 防止点击面板内部冒泡到关闭手势
      onTap: () {},
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: Colors.black.withValues(alpha: 0.55),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖拽指示 + 固定/关闭按钮
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
                    // 📌 固定按钮
                    GestureDetector(
                      onTap: () => setState(() => _isPinned = !_isPinned),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                          color: _isPinned ? Colors.white : Colors.white54,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ✕ 关闭按钮
                    GestureDetector(
                      onTap: _closePanel,
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white54, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 信息行列表
                ..._buildInfoRows(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildInfoRows(BuildContext context) {
    final image = widget.imageRow;
    final rows = <_InfoItem>[];

    // 拍摄时间
    if (image.takenAt != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(image.takenAt!);
      rows.add(_InfoItem(
        icon: Icons.calendar_today_rounded,
        label: '拍摄时间',
        value: '${dt.year}年${dt.month}月${dt.day}日  '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
      ));
    }

    // 分辨率 + 大小
    rows.add(_InfoItem(
      icon: Icons.photo_size_select_actual_rounded,
      label: '尺寸',
      value: '${image.width} × ${image.height}  ·  '
          '${(image.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
    ));

    // 清晰度（用语言友好描述）
    if (image.isAnalyzed) {
      final blurLabel = _blurLabel(image.blurScore);
      rows.add(_InfoItem(
        icon: Icons.lens_blur_rounded,
        label: '清晰度',
        value: blurLabel,
      ));
    }

    // 截图 / 含文字
    final badges = <String>[];
    if (image.isScreenshot) badges.add('截图');
    if (image.hasText) badges.add('含文字');
    if (badges.isNotEmpty) {
      rows.add(_InfoItem(
        icon: Icons.label_outline_rounded,
        label: '属性',
        value: badges.join('  ·  '),
      ));
    }

    // 色温
    if (image.isAnalyzed) {
      rows.add(_InfoItem(
        icon: Icons.thermostat_rounded,
        label: '色温',
        value: _warmthLabel(image.colorWarmth),
      ));
    }

    // AI 识别标签
    if (image.tags != null && image.tags!.isNotEmpty) {
      // 显示前 3 个标签，简洁
      final tagList = image.tags!.split(',').take(3).map((t) => t.trim()).join('  ·  ');
      rows.add(_InfoItem(
        icon: Icons.auto_awesome_rounded,
        label: 'AI 识别',
        value: tagList,
      ));
    }

    return rows
        .map((item) => _buildRow(item))
        .toList();
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

  // ── 辅助：清晰度语言描述 ──────────────────────────────────────────────────
  String _blurLabel(double score) {
    if (score >= 500) return '非常清晰';
    if (score >= 200) return '清晰';
    if (score >= 80)  return '较清晰';
    if (score >= 30)  return '轻微模糊';
    return '模糊';
  }

  // ── 辅助：色温语言描述 ─────────────────────────────────────────────────────
  String _warmthLabel(double warmth) {
    if (warmth > 0.3)  return '暖调（红/橙/黄）';
    if (warmth > 0.1)  return '偏暖';
    if (warmth < -0.3) return '冷调（蓝/青）';
    if (warmth < -0.1) return '偏冷';
    return '中性';
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({required this.icon, required this.label, required this.value});
}
