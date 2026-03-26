import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageDetailScreen extends StatelessWidget {
  final dynamic imageRow;

  const ImageDetailScreen({super.key, required this.imageRow});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('特征透视与详情分析')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: imageRow.id,
              child: Image.file(
                File(imageRow.filePath),
                fit: BoxFit.contain,
                width: double.infinity,
                height: 400,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 底层机器视觉提取特征', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 16),
                  _buildFeatureTile(context, Icons.lens_blur_rounded, '拉普拉斯方差 (模糊度)', '${imageRow.blurScore.toStringAsFixed(2)}'),
                  _buildFeatureTile(context, Icons.text_snippet_rounded, 'OCR 文字检出', imageRow.hasText ? '是' : '否'),
                  _buildFeatureTile(context, Icons.screenshot_rounded, '截图判定', imageRow.isScreenshot ? '是' : '否'),
                  if (imageRow.tags != null && imageRow.tags.toString().isNotEmpty)
                    _buildFeatureTile(context, Icons.local_offer_rounded, '1000 级细分纯物体标签 (Top 3)', imageRow.tags.toString().toUpperCase()),
                  _buildFeatureTile(context, Icons.auto_awesome_mosaic_rounded, '隐性特征张量池 (TFLite)', _getVectorPreview(imageRow.semanticVector)),
                  
                  const SizedBox(height: 40),
                  
                  Text('文件元数据', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildFeatureTile(context, Icons.photo_size_select_actual_rounded, '照片物理分辨率', '${imageRow.width} x ${imageRow.height}'),
                  _buildFeatureTile(context, Icons.sd_storage_rounded, '纯体积大小', '${(imageRow.fileSize / 1024 / 1024).toStringAsFixed(2)} MB'),
                  _buildFeatureTile(context, Icons.fingerprint_rounded, '漂移哈希表散列 ID', imageRow.id, isMini: true),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(BuildContext context, IconData icon, String label, String value, {bool isMini = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: isMini ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16)
            ),
            child: Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary)
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.normal)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMini ? 10 : 16)),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _getVectorPreview(dynamic semanticVector) {
    if (semanticVector == null || semanticVector.isEmpty) {
      return '尚未提取或提取失败';
    }
    try {
      final floats = Float32List.view(semanticVector.buffer);
      final preview = floats.take(4).map((e) => e.toStringAsFixed(3)).join(', ');
      return '已提取 ${floats.length} 维 [ $preview ... ]';
    } catch (e) {
      return '数据格式异常';
    }
  }
}
