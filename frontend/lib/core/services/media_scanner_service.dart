// media_scanner_service.dart
// 媒体扫描服务：两阶段解耦扫描架构
//
// Phase 1 — 快速元数据入库（scanAndIndexMetadata）
//   扫描手机相册，将所有图片的元数据（路径/尺寸/时间等）写入数据库
//   标记 isAnalyzed=false，不执行任何 AI 推理，速度极快
//   通过 onProgress 回调实时汇报入库进度
//
// Phase 2 — 后台 AI 特征提取（analyzeUnanalyzedImages）
//   从数据库取出所有 isAnalyzed=false 的记录
//   逐张调用 FeatureExtractorService 执行双管线 AI 推理
//   UI 通过 watchAnalyzedImagesCount() Stream 自动感知进度，无需额外回调
//   支持软中断（cancelAnalysis）

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'feature_extractor_service.dart';
import 'smart_folder_matcher_service.dart';

/// 元数据入库每批大小（无 AI，可以更大）
const _kIndexPageSize = 100;

/// AI 分析每张间隔（让主线程有喘息，避免 UI 掉帧）
const _kAnalysisDelay = Duration(milliseconds: 20);

class MediaScannerService {
  final AppDatabase database;
  final FeatureExtractorService extractor;
  final SmartFolderMatcherService matcher;

  bool _isScanCancelled = false;
  bool _isAnalysisCancelled = false;

  // 暴露给外部判断当前是否正在后台分析
  bool get isAnalyzing => _analysisRunning;
  bool _analysisRunning = false;

  MediaScannerService(this.database, this.extractor, this.matcher);

  /// 中断元数据入库阶段
  void cancelScan() => _isScanCancelled = true;

  /// 中断后台 AI 分析阶段
  void cancelAnalysis() => _isAnalysisCancelled = true;

  // ===========================================================================
  // Phase 1：快速元数据入库
  // ===========================================================================

  /// 快速扫描手机相册，将所有图片元数据写入数据库（不执行 AI）。
  ///
  /// [onProgress] 每批入库后回调：(已入库张数, 相册总张数)
  ///              第一次调用即携带总张数，让 UI 在扫描开始瞬间显示完整总量
  ///
  /// 返回：本次新入库的图片数量
  Future<int> scanAndIndexMetadata({
    void Function(int indexed, int total)? onProgress,
  }) async {
    _isScanCancelled = false;

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && ps != PermissionState.limited) {
      throw Exception('未获得相册访问权限，请在系统设置中授权');
    }

    final paths = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (paths.isEmpty) return 0;

    // 优先使用 isAll=true 的虚拟总相册（包含截图/Downloads/所有App图片）
    final AssetPathEntity allPath =
        paths.firstWhere((p) => p.isAll, orElse: () => paths.first);

    final int totalCount = await allPath.assetCountAsync;
    debugPrint('MediaScanner Phase1: 发现 $totalCount 张图片');

    // ★ 立即回调总数，UI 顶部大数字在扫描开始瞬间就能显示完整总量
    onProgress?.call(0, totalCount);

    int newCount = 0;
    int page = 0;
    int indexed = 0;

    while (!_isScanCancelled) {
      final int start = page * _kIndexPageSize;
      if (start >= totalCount) break;

      final batch = await allPath.getAssetListRange(
        start: start,
        end: (start + _kIndexPageSize).clamp(0, totalCount),
      );
      if (batch.isEmpty) break;

      for (final entity in batch) {
        if (_isScanCancelled) break;
        final isNew = await _insertMetadataOnly(entity);
        if (isNew) newCount++;
        indexed++;
      }

      // 每批（100张）汇报一次入库进度
      onProgress?.call(indexed, totalCount);
      page++;
    }

    debugPrint('MediaScanner Phase1: 完成，新入库 $newCount 张');
    return newCount;
  }

  /// 只插入元数据（不做 AI），返回是否为新记录
  Future<bool> _insertMetadataOnly(AssetEntity entity) async {
    final file = await entity.file;
    if (file == null) return false;

    final idHash = sha256.convert(utf8.encode(file.absolute.path)).toString();

    // 已存在则跳过（无论是否已分析）
    final existing = await (database.select(database.images)
          ..where((t) => t.id.equals(idHash)))
        .getSingleOrNull();
    if (existing != null) return false;

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
        // AI 字段初始值，等待 Phase 2 填充
        blurScore: 0.0,
        dominantHue: 0.0,
        colorWarmth: 0.0,
        semanticVector: Uint8List(0),
      ),
    );

    return true;
  }

  // ===========================================================================
  // Phase 2：后台 AI 特征提取
  // ===========================================================================

  /// 对数据库中所有 isAnalyzed=false 的图片逐张执行 AI 特征提取。
  ///
  /// 设计为"后台静默运行"：调用方可不 await，UI 通过
  /// database.watchAnalyzedImagesCount() Stream 自动感知进度。
  ///
  /// 完成后自动触发智能文件夹规则匹配。
  Future<void> analyzeUnanalyzedImages() async {
    if (_analysisRunning) {
      debugPrint('MediaScanner Phase2: 已在运行中，跳过重复启动');
      return;
    }
    _isAnalysisCancelled = false;
    _analysisRunning = true;

    try {
      // 取出所有未分析记录
      final unanalyzed = await (database.select(database.images)
            ..where((t) => t.isAnalyzed.equals(false)))
          .get();

      debugPrint('MediaScanner Phase2: 待分析 ${unanalyzed.length} 张');

      for (final image in unanalyzed) {
        if (_isAnalysisCancelled) break;

        // 获取该图片的缩略图（防 OOM）
        final assets =
            await PhotoManager.getAssetListRange(start: 0, end: 1);
        // 直接用原始文件，thumbnail 逻辑在 extractFeaturesForImage 内部处理
        await extractor.extractFeaturesForImage(image.id, image.filePath);

        // 轻微延迟，避免 AI 推理占满主线程导致 UI 卡顿
        await Future.delayed(_kAnalysisDelay);
      }

      // 全部分析完毕，触发规则匹配
      if (!_isAnalysisCancelled) {
        final matched = await matcher.runMatchForAll();
        debugPrint('MediaScanner Phase2: 规则匹配完成，共归类 $matched 条');
      }
    } finally {
      _analysisRunning = false;
    }
  }

  // ===========================================================================
  // 清理孤儿记录
  // ===========================================================================

  /// 清理数据库中文件已从手机删除的僵尸记录
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
