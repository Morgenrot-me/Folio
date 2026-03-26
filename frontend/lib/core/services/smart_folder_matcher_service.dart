// smart_folder_matcher_service.dart
// 智能规则匹配引擎：遍历全部已分析图片，按规则树评估是否符合每个智能文件夹，
// 将匹配结果写入 image_folder_map 表。
//
// 规则树节点类型：
//   AND  - 所有子节点均满足才通过
//   OR   - 任意子节点满足即通过
//   NOT  - 唯一子节点不满足才通过
//   LEAF - 叶节点：评估单个图片特征与阈值的比较

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart' hide Value;
import 'package:drift/drift.dart' as drift show Value;

class SmartFolderMatcherService {
  final AppDatabase database;
  final _uuid = const Uuid();

  SmartFolderMatcherService(this.database);

  /// 对全部（或指定）智能文件夹执行一次完整匹配，返回总写入条数
  Future<int> runMatchForAll() async {
    // 获取所有智能文件夹
    final folders = await database.select(database.smartFolders).get();
    if (folders.isEmpty) return 0;

    // 获取所有已分析完成的图片（只匹配 isAnalyzed=true 的有效记录）
    final images = await (database.select(database.images)
          ..where((t) => t.isAnalyzed.equals(true)))
        .get();
    if (images.isEmpty) return 0;

    int totalMatched = 0;

    for (final folder in folders) {
      // 加载本文件夹的所有规则节点
      final rules = await (database.select(database.folderRules)
            ..where((t) => t.folderId.equals(folder.id)))
          .get();

      if (rules.isEmpty || folder.rootRuleId == null) continue;

      final rootRule = rules.firstWhere(
        (r) => r.id == folder.rootRuleId,
        orElse: () => rules.first,
      );

      // 清除本文件夹旧的自动匹配记录（以便处理规则更新后的重匹配）
      await (database.delete(database.imageFolderMap)
            ..where((t) =>
                t.folderId.equals(folder.id) &
                t.source.equals('AUTO')))
          .go();

      // 逐图评估
      final matchedImageIds = <String>[];
      for (final image in images) {
        if (_evaluateNode(rootRule, rules, image)) {
          matchedImageIds.add(image.id);
        }
      }

      // 批量写入 image_folder_map
      for (final imageId in matchedImageIds) {
        await database.into(database.imageFolderMap).insertOnConflictUpdate(
          ImageFolderMapCompanion(
            id: drift.Value(_uuid.v4()),
            imageId: drift.Value(imageId),
            folderId: drift.Value(folder.id),
            source: const drift.Value('AUTO'),
            assignedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
            isPhysicalPrimary: const drift.Value(false),
          ),
        );
      }

      // 更新文件夹最后匹配时间
      await (database.update(database.smartFolders)
            ..where((t) => t.id.equals(folder.id)))
          .write(SmartFoldersCompanion(
        lastMatchedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
      ));

      totalMatched += matchedImageIds.length;
      debugPrint(
          'SmartFolderMatcher: 文件夹「${folder.name}」匹配 ${matchedImageIds.length} 张');
    }

    return totalMatched;
  }

  // =========================================================================
  // 规则树评估
  // =========================================================================

  /// 递归评估规则节点
  bool _evaluateNode(FolderRule node, List<FolderRule> allRules, Image image) {
    switch (node.nodeType) {
      case 'AND':
        final children = allRules.where((r) => r.parentId == node.id).toList();
        // AND 节点无子节点时视为通过（空条件 = 全接收）
        if (children.isEmpty) return true;
        return children.every((c) => _evaluateNode(c, allRules, image));

      case 'OR':
        final children = allRules.where((r) => r.parentId == node.id).toList();
        if (children.isEmpty) return false;
        return children.any((c) => _evaluateNode(c, allRules, image));

      case 'NOT':
        final children = allRules.where((r) => r.parentId == node.id).toList();
        if (children.isEmpty) return true;
        return !_evaluateNode(children.first, allRules, image);

      case 'LEAF':
        return _evaluateLeaf(node, image);

      default:
        return false;
    }
  }

  /// 评估叶节点（单个特征条件）
  bool _evaluateLeaf(FolderRule node, Image image) {
    final featureType = node.featureType;
    final comparator = node.comparator;
    final rawValue = node.value;

    if (featureType == null || comparator == null || rawValue == null) {
      return false;
    }

    switch (featureType) {
      case 'IS_SCREENSHOT':
        final expected = rawValue.toLowerCase() == 'true';
        return comparator == '==' ? image.isScreenshot == expected : image.isScreenshot != expected;

      case 'HAS_TEXT':
        final expected = rawValue.toLowerCase() == 'true';
        return comparator == '==' ? image.hasText == expected : image.hasText != expected;

      case 'BLUR_SCORE':
        final threshold = double.tryParse(rawValue);
        if (threshold == null) return false;
        return _compareDouble(image.blurScore, comparator, threshold);

      case 'DOMINANT_HUE':
        final threshold = double.tryParse(rawValue);
        if (threshold == null) return false;
        return _compareDouble(image.dominantHue, comparator, threshold);

      case 'COLOR_WARMTH':
        final threshold = double.tryParse(rawValue);
        if (threshold == null) return false;
        return _compareDouble(image.colorWarmth, comparator, threshold);

      default:
        return false;
    }
  }

  bool _compareDouble(double actual, String comparator, double threshold) {
    switch (comparator) {
      case '>':  return actual > threshold;
      case '>=': return actual >= threshold;
      case '<':  return actual < threshold;
      case '<=': return actual <= threshold;
      case '==': return (actual - threshold).abs() < 1e-6;
      case '!=': return (actual - threshold).abs() >= 1e-6;
      default:   return false;
    }
  }
}
