// media_scanner_service.dart
// 媒体扫描服务：负责请求相册权限、分页遍历图片并调用特征提取管线落库。
// 核心设计：
//   - 分页加载（每批 50 张），避免万张图库一次性 OOM；
//   - 取消令牌支持，扫描可随时中断；
//   - 改用 isAnalyzed 标志判断是否需要重分析，不再依赖不可靠的 blurScore==0。

import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:photo_manager/photo_manager.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart';
import 'feature_extractor_service.dart';

/// 每批处理的图片数量
const _kPageSize = 50;

class MediaScannerService {
  final AppDatabase database;
  final FeatureExtractorService extractor;

  /// 取消令牌：set 为 true 可中断正在运行的扫描任务
  bool _isCancelled = false;

  MediaScannerService(this.database, this.extractor);

  /// 中断当前正在进行的扫描
  void cancelScan() {
    _isCancelled = true;
  }

  /// 请求权限并全量扫描（分批分页），返回本次新索引的图片数量
  Future<int> scanAndIndexNewImages() async {
    _isCancelled = false;

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && ps != PermissionState.limited) {
      throw Exception('PhotoManager: 未获得相册访问权限');
    }

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );
    if (paths.isEmpty) return 0;

    // MVP 阶段仅扫描主相册（Recent/All）
    final AssetPathEntity recentPath = paths.first;
    final int totalCount = await recentPath.assetCountAsync;

    int newCount = 0;
    int page = 0;

    // 分页循环，每次只取 _kPageSize 张
    while (!_isCancelled) {
      final int start = page * _kPageSize;
      if (start >= totalCount) break;

      final List<AssetEntity> batch = await recentPath.getAssetListRange(
        start: start,
        end: (start + _kPageSize).clamp(0, totalCount),
      );
      if (batch.isEmpty) break;

      for (final entity in batch) {
        if (_isCancelled) break;
        final isNew = await _processAndSaveAsset(entity);
        if (isNew) newCount++;
      }

      page++;
    }

    return newCount;
  }

  /// 转换并在数据库不存在时落表，返回是否为新增记录
  Future<bool> _processAndSaveAsset(AssetEntity entity) async {
    final file = await entity.file;
    if (file == null) return false;

    // 基于绝对路径生成稳定哈希 ID
    final idHash = sha256.convert(utf8.encode(file.absolute.path)).toString();

    final existing = await (database.select(database.images)
          ..where((tbl) => tbl.id.equals(idHash)))
        .getSingleOrNull();

    if (existing == null) {
      // 新图片：先落表基础元数据，再触发特征提取流水线
      await database.into(database.images).insert(
        ImagesCompanion.insert(
          id: idHash,
          filePath: file.absolute.path,
          fileName: entity.title ?? file.path.split('/').last,
          width: entity.width,
          height: entity.height,
          fileSize: (await file.length()),
          indexedAt: DateTime.now().millisecondsSinceEpoch,
          blurScore: 0.0,
          dominantHue: 0.0,
          colorWarmth: 0.0,
          semanticVector: Uint8List(0),
        ),
      );

      final thumbBytes = await entity.thumbnailDataWithSize(const ThumbnailSize(512, 512));
      await extractor.extractFeaturesForImage(idHash, file.absolute.path, thumbBytes);

      // 给 UI 线程 30ms 呼吸窗口，防止动画卡顿
      await Future.delayed(const Duration(milliseconds: 30));
      return true;
    } else if (!existing.isAnalyzed) {
      // 历史记录：AI 分析未完成（早期版本或中途中断）则静默补跑
      final thumbBytes = await entity.thumbnailDataWithSize(const ThumbnailSize(512, 512));
      await extractor.extractFeaturesForImage(idHash, file.absolute.path, thumbBytes);
      await Future.delayed(const Duration(milliseconds: 30));
    }

    return false;
  }
}
