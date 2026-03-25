import 'dart:io';
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
                  _buildFeatureTile(context, Icons.lens_blur_rounded, '拉普拉斯局部梯度的方差 (清晰度/模糊度)', '${imageRow.blurScore.toStringAsFixed(2)}'),
                  _buildFeatureTile(context, Icons.text_snippet_rounded, 'OCR Google 结构文字检出', imageRow.hasText ? '检测出大量字符体' : '未见有效字符'),
                  _buildFeatureTile(context, Icons.screenshot_rounded, '基础系统系统快捷截图判定', imageRow.isScreenshot ? '是系统截图' : '纯相机拍摄照片'),
                  _buildFeatureTile(context, Icons.auto_awesome_mosaic_rounded, 'AI 多模态大模型 512维语义量词张量 (TFLite)', imageRow.semanticVector.isNotEmpty ? '向量已被高密度挤压存入底层' : '尚处于等待处理的原始态队列中'),
                  
                  const SizedBox(height: 40),
                  
                  Text('📋 相机元数据探针', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
}
