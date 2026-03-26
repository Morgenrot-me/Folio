// image_detail_screen.dart
// 图片特征详情页：展示单张图片的 AI 提取特征与文件元数据。
// 修复：使用 `as db` 前缀隔离 Drift Image 与 Flutter Image，消除命名冲突

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart'; // Flutter Image widget 正常使用
import '../../core/database/app_database.dart' as db; // Drift 类型加 db. 前缀避冲突

class ImageDetailScreen extends StatelessWidget {
  final db.Image imageRow; // Drift 生成的图片数据模型
  final Object heroTag;

  const ImageDetailScreen({
    super.key,
    required this.imageRow,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final imgHeight = MediaQuery.of(context).size.height * 0.45;

    return Scaffold(
      appBar: AppBar(title: const Text('特征透视与详情分析')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: heroTag,
              child: Image.file( // Flutter Image widget
                File(imageRow.filePath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: imgHeight,
                frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) return child;
                  return SizedBox(
                    height: imgHeight,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (ctx, err, stack) => SizedBox(
                  height: imgHeight,
                  child: Center(
                    child: Icon(Icons.broken_image_outlined,
                        size: 64,
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.2)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 底层机器视觉提取特征',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureTile(context, Icons.lens_blur_rounded,
                      '拉普拉斯方差（模糊度）', '${imageRow.blurScore.toStringAsFixed(2)}'),
                  _buildFeatureTile(context, Icons.text_snippet_rounded,
                      'OCR 文字检出', imageRow.hasText ? '是' : '否'),
                  _buildFeatureTile(context, Icons.screenshot_rounded,
                      '截图判定', imageRow.isScreenshot ? '是' : '否'),
                  _buildFeatureTile(context, Icons.check_circle_outline_rounded,
                      'AI 特征提取完成', imageRow.isAnalyzed ? '✓ 已完成' : '⏳ 待分析'),
                  _buildFeatureTile(
                    context,
                    Icons.thermostat_rounded,
                    '色温冷暖（-1 冷 ~ +1 暖）',
                    imageRow.colorWarmth.toStringAsFixed(3),
                  ),
                  _buildFeatureTile(
                    context,
                    Icons.palette_rounded,
                    '主色调（色相角度 0-360°）',
                    '${imageRow.dominantHue.toStringAsFixed(1)}°',
                  ),
                  if (imageRow.tags != null && imageRow.tags!.isNotEmpty)
                    _buildFeatureTile(
                      context,
                      Icons.local_offer_rounded,
                      '1000 级细分物体标签（Top 6）',
                      imageRow.tags!.toUpperCase(),
                    ),
                  _buildFeatureTile(
                    context,
                    Icons.auto_awesome_mosaic_rounded,
                    '隐性特征张量池（TFLite）',
                    _getVectorPreview(imageRow.semanticVector),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    '文件元数据',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureTile(context, Icons.photo_size_select_actual_rounded,
                      '照片物理分辨率', '${imageRow.width} × ${imageRow.height}'),
                  _buildFeatureTile(context, Icons.sd_storage_rounded,
                      '文件大小',
                      '${(imageRow.fileSize / 1024 / 1024).toStringAsFixed(2)} MB'),
                  _buildFeatureTile(
                    context,
                    Icons.fingerprint_rounded,
                    '索引散列 ID',
                    imageRow.id,
                    isMini: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(BuildContext context, IconData icon, String label,
      String value, {bool isMini = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: isMini ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: isMini ? 10 : 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getVectorPreview(dynamic semanticVector) {
    if (semanticVector == null) return '尚未提取或提取失败';
    try {
      // semanticVector 在数据库中存为 Uint8List
      final bytes = semanticVector as Uint8List;
      if (bytes.isEmpty) return '尚未提取或提取失败';
      final floats = Float32List.view(bytes.buffer);
      if (floats.isEmpty) return '数据格式异常';
      final preview = floats.take(4).map((e) => e.toStringAsFixed(3)).join(', ');
      return '已提取 ${floats.length} 维 [ $preview … ]';
    } catch (e) {
      return '数据格式异常';
    }
  }
}
