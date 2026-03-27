// media_scanner_service.dart
// 媒体扫描服务：权限申请 → 所有相册分页扫描 → 特征提取 → 规则匹配。
// 改善：
//   - 从 paths.first 改为「找 isAll 虚拟总相册」，确保截图/Downloads/第三方App图全部入库
//   - 写入 takenAt 拍摄时间（来自 AssetEntity.createDateTime）
//   - 新增 cleanOrphanedImages()：清理已从手机删除但仍在数据库的僵尸记录

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'feature_extractor_service.dart';
import 'smart_folder_matcher_service.dart';

/// 每批处理的图片数量（防 OOM）
const _kPageSize = 50;

class MediaScannerService {
  final AppDatabase database;
  final FeatureExtractorService extractor;
  final SmartFolderMatcherService matcher;

  bool _isCancelled = false;

  MediaScannerService(this.database, this.extractor, this.matcher);

  /// 中断正在进行的扫描
  void cancelScan() => _isCancelled = true;

  /// 完整扫描流程：
  ///   1. 获取所有相册中的图片（isAll 虚拟总相册）
  ///   2. **立即**通过 onProgress 汇报手机相册总张数（totalInLibrary）
  ///   3. 分页处理：新图片落库+特征提取，未分析图片补跑
  ///   4. 扫描完成后触发智能规则匹配
  ///
  /// [onProgress] 回调参数说明：
  ///   processed — 本次扫描已处理的张数（入库或跳过）
  ///   total     — 手机相册中的总张数（固定值，第一次回调即确定）
  Future<int> scanAndIndexNewImages({
    void Function(int processed, int total)? onProgress,
  }) async {
    _isCancelled = false;

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && ps != PermissionState.limited) {
      throw Exception('未获得相册访问权限，请在系统设置中授权');
    }

    // 使用 isAll=true 的虚拟总相册，包含截图/Downloads/所有App图片
    final paths = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (paths.isEmpty) return 0;

    final AssetPathEntity allPath =
        paths.firstWhere((p) => p.isAll, orElse: () => paths.first);

    final int totalCount = await allPath.assetCountAsync;
    debugPrint('MediaScanner: 发现 $totalCount 张图片（相册: ${allPath.name}）');

    // ★ 关键：在任何入库之前，先把手机相册总张数回调给 UI
    //   这样 HomeScreen 顶部大数字在扫描开始瞬间就能显示完整总量
    onProgress?.call(0, totalCount);

    int newCount = 0;
    int page = 0;
    int processed = 0;

    while (!_isCancelled) {
      final int start = page * _kPageSize;
      if (start >= totalCount) break;

      final batch = await allPath.getAssetListRange(
        start: start,
        end: (start + _kPageSize).clamp(0, totalCount),
      );
      if (batch.isEmpty) break;

      for (final entity in batch) {
        if (_isCancelled) break;
        final isNew = await _processAndSaveAsset(entity);
        if (isNew) newCount++;
        processed++;
      }

      // 每处理完一批（50张）更新进度
      onProgress?.call(processed, totalCount);
      page++;
    }

    // 扫描完成后触发全量规则匹配
    if (!_isCancelled) {
      final matched = await matcher.runMatchForAll();
      debugPrint('MediaScanner: 规则匹配完成，共归类 $matched 条图片-文件夹记录');
    }

    return newCount;
  }


  /// 处理单张资产：新图片落库+分析，已有未分析图片补分析
  Future<bool> _processAndSaveAsset(AssetEntity entity) async {
    final file = await entity.file;
    if (file == null) return false;

    final idHash = sha256.convert(utf8.encode(file.absolute.path)).toString();

    final existing = await (database.select(database.images)
          ..where((t) => t.id.equals(idHash)))
        .getSingleOrNull();

    if (existing == null) {
      // 写入 takenAt 拍摄时间（来自相册元数据，比 indexedAt 更有意义）
      final takenAtMs = entity.createDateTime != null
          ? entity.createDateTime!.millisecondsSinceEpoch
          : null;

      await database.into(database.images).insert(
        ImagesCompanion.insert(
          id: idHash,
          filePath: file.absolute.path,
          fileName: entity.title ?? file.path.split('/').last,
          width: entity.width,
          height: entity.height,
          fileSize: await file.length(),
          indexedAt: DateTime.now().millisecondsSinceEpoch,
          takenAt: takenAtMs != null ? Value(takenAtMs) : const Value.absent(),
          blurScore: 0.0,
          dominantHue: 0.0,
          colorWarmth: 0.0,
          semanticVector: Uint8List(0),
        ),
      );

      final thumbBytes =
          await entity.thumbnailDataWithSize(const ThumbnailSize(512, 512));
      await extractor.extractFeaturesForImage(idHash, file.absolute.path, thumbBytes);

      // 30ms 呼吸窗口，减少 UI 掉帧
      await Future.delayed(const Duration(milliseconds: 30));
      return true;
    } else if (!existing.isAnalyzed) {
      // 历史记录未分析，静默补跑
      final thumbBytes =
          await entity.thumbnailDataWithSize(const ThumbnailSize(512, 512));
      await extractor.extractFeaturesForImage(idHash, file.absolute.path, thumbBytes);
      await Future.delayed(const Duration(milliseconds: 30));
    }

    return false;
  }

  /// 清理孤儿记录：检查数据库中每条图片记录对应的文件是否仍存在，
  /// 删除已从手机中移除的僵尸记录（外键级联自动清理对应的 image_folder_map）。
  /// 建议在每次扫描完成后或用户手动触发时调用。
  Future<int> cleanOrphanedImages() async {
    final allImages = await database.select(database.images).get();
    int removed = 0;

    for (final image in allImages) {
      final exists = await File(image.filePath).exists();
      if (!exists) {
        await (database.delete(database.images)
              ..where((t) => t.id.equals(image.id)))
            .go();
        removed++;
        debugPrint('MediaScanner: 清理僵尸记录 ${image.fileName}');
      }
    }

    if (removed > 0) {
      debugPrint('MediaScanner: 清理完成，共删除 $removed 条孤儿记录');
    }
    return removed;
  }
}
