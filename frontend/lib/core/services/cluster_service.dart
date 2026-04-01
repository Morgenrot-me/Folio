// cluster_service.dart
// 后台 AI 聚类服务：
// 利用 pHash 精准去重 (找出非常相似或相同的图片)
// 结合 MobileCLIP (512维度特征) 使用无监督 DBSCAN 发现语义极度相近的场景相册。
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart' hide Value;
import 'package:drift/drift.dart' as drift show Value;

class ClusterService {
  final AppDatabase database;
  ClusterService(this.database);

  /// 运行全量无监督自动聚类
  Future<int> runClustering() async {
    // 1. 获取所有已分析的图片
    final images = await (database.select(database.images)
          ..where((t) => t.isAnalyzed.equals(true)))
        .get();
    if (images.isEmpty) return 0;

    // 清空现有聚类，并移除所有已绑定的 clusterId
    await database.delete(database.clusters).go();
    await (database.update(database.images)
          ..where((t) => t.clusterId.isNotNull()))
        .write(const ImagesCompanion(clusterId: drift.Value(null)));

    int totalClusters = 0;
    final uuid = const Uuid();

    // 2. 基于 pHash 的精准去重 (汉明距离 <= 3 视为连拍或重复照片)
    final processedForPhash = <String>{};
    for (int i = 0; i < images.length; i++) {
      final imgA = images[i];
      if (processedForPhash.contains(imgA.id) || imgA.phash == null) continue;

      final currentGroup = [imgA];
      processedForPhash.add(imgA.id);

      for (int j = i + 1; j < images.length; j++) {
        final imgB = images[j];
        if (processedForPhash.contains(imgB.id) || imgB.phash == null) continue;

        final xor = imgA.phash! ^ imgB.phash!;
        final distance = _popcount(xor);

        if (distance <= 3) {
          currentGroup.add(imgB);
          processedForPhash.add(imgB.id);
        }
      }

      if (currentGroup.length > 1) {
        final cId = uuid.v4();
        await database.into(database.clusters).insert(ClustersCompanion(
          id: drift.Value(cId),
          name: const drift.Value('高度相似 (去重)'),
          centroidVector: drift.Value(imgA.clipVector ?? Uint8List(0)),
          imageCount: drift.Value(currentGroup.length),
          createdAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
        ));
        for (final img in currentGroup) {
          await (database.update(database.images)
                ..where((t) => t.id.equals(img.id)))
              .write(ImagesCompanion(clusterId: drift.Value(cId)));
        }
        totalClusters++;
      }
    }

    // 3. 基于 DBSCAN 的语义聚类 (MobileCLIP 512D 余弦相似度)
    // 获取未归入去重组的剩余图片
    final remainingImages = await (database.select(database.images)
          ..where((t) => t.isAnalyzed.equals(true) & t.clusterId.isNull()))
        .get();

    final clipImages = remainingImages
        .where((im) => im.clipVector != null && im.clipVector!.isNotEmpty)
        .toList();

    if (clipImages.length >= 3) {
      // 放入后台 Isolate 执行，防止卡顿 UI，返回二维数组
      final dbscanResult = await compute(_runDbscan, clipImages);

      for (final clusterGroup in dbscanResult) {
        if (clusterGroup.length < 3) continue; // 小于3张不作为聚类相册

        final cId = uuid.v4();
        await database.into(database.clusters).insert(ClustersCompanion(
          id: drift.Value(cId),
          name: const drift.Value(''), // 默认留空
          centroidVector: drift.Value(clusterGroup.first.clipVector!),
          imageCount: drift.Value(clusterGroup.length),
          createdAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
        ));

        for (final img in clusterGroup) {
          await (database.update(database.images)
                ..where((t) => t.id.equals(img.id)))
              .write(ImagesCompanion(clusterId: drift.Value(cId)));
        }
        totalClusters++;
      }
    }

    return totalClusters;
  }

  // 计算 64-bit 汉明重量 (popcount)
  static int _popcount(int x) {
    int count = 0;
    while (x != 0) {
      count++;
      x &= x - 1;
    }
    return count;
  }

  // ---------------------------------------------------------------------------
  // 运行在 Isolate 的 DBSCAN 算法
  // ---------------------------------------------------------------------------
  static List<List<Image>> _runDbscan(List<Image> images) {
    const double eps = 0.12; // 余弦距离阈值 (相似度 >= 0.88)
    const int minPts = 3;

    final visited = <String>{};
    final clusters = <List<Image>>[];
    final isNoise = <String>{};

    for (int i = 0; i < images.length; i++) {
      final img = images[i];
      if (visited.contains(img.id)) continue;
      visited.add(img.id);

      final neighbors = _regionQuery(images, img, eps);
      if (neighbors.length < minPts) {
        isNoise.add(img.id);
      } else {
        final currentCluster = <Image>[img];
        clusters.add(currentCluster);

        // Expand cluster
        final seedSet = List<Image>.from(neighbors);
        seedSet.remove(img);

        for (int j = 0; j < seedSet.length; j++) {
          final q = seedSet[j];
          if (isNoise.contains(q.id)) {
            isNoise.remove(q.id);
            if (!currentCluster.any((c) => c.id == q.id)) {
              currentCluster.add(q);
            }
          }
          if (!visited.contains(q.id)) {
            visited.add(q.id);
            final qNeighbors = _regionQuery(images, q, eps);
            if (qNeighbors.length >= minPts) {
              // 避免 seedSet 里重复添加同一个对象（简单通过判断 id）
              for (final n in qNeighbors) {
                if (!seedSet.any((item) => item.id == n.id)) {
                  seedSet.add(n);
                }
              }
            }
            if (!currentCluster.any((c) => c.id == q.id)) {
              currentCluster.add(q);
            }
          }
        }
      }
    }
    return clusters;
  }

  static List<Image> _regionQuery(List<Image> images, Image q, double eps) {
    final neighbors = <Image>[];
    final qVec = Float32List.view(q.clipVector!.buffer);
    for (int i = 0; i < images.length; i++) {
      final p = images[i];
      final pVec = Float32List.view(p.clipVector!.buffer);
      if (_cosineDistance(qVec, pVec) <= eps) {
        neighbors.add(p);
      }
    }
    return neighbors;
  }

  static double _cosineDistance(Float32List a, Float32List b) {
    double dotProduct = 0.0;
    // clipVector 模型输出已经是 L2 归一化过的，所以余弦相似度就是简单的点乘
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
    }
    // 防止浮点误差
    return (1.0 - dotProduct).clamp(0.0, 2.0);
  }
}
