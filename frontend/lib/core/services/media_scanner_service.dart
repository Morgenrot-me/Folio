import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:photo_manager/photo_manager.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart';
import 'feature_extractor_service.dart';

class MediaScannerService {
  final AppDatabase database;
  final FeatureExtractorService extractor;

  MediaScannerService(this.database, this.extractor);

  /// 请求权限并全量扫描一次相册（获取未索引的图片对象）
  Future<void> scanAndIndexNewImages() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && ps != PermissionState.limited) {
      throw Exception('PhotoManager: Permission not granted');
    }

    // 获取相册列表
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );
    if (paths.isEmpty) return;

    // 为了 MVP，仅遍历主相册 Recent/All
    final AssetPathEntity recentPath = paths.first;
    // 获取全部图库 (为防止过大, 暂且分页或按量获取, MVP设计下假定单次读取或放入队列)
    final int assetCount = await recentPath.assetCountAsync;
    final List<AssetEntity> entities = await recentPath.getAssetListRange(start: 0, end: assetCount);

    for (final entity in entities) {
      await _processAndSaveAsset(entity);
    }
  }

  /// 转换并在数据库不存在时落表
  Future<void> _processAndSaveAsset(AssetEntity entity) async {
    final file = await entity.file;
    if (file == null) return;
    
    // 生成基于路径的固定哈希作为 ID
    final idHash = sha256.convert(utf8.encode(file.absolute.path)).toString();

    // 检查是否已存在
    final existing = await (database.select(database.images)
          ..where((tbl) => tbl.id.equals(idHash)))
        .getSingleOrNull();

    if (existing == null) {
      // 在这里仅存入基础元数据，特征留待[特征提取层]补齐
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
          semanticVector: Uint8List(0), // 提供一个空的初始向量
        ),
      );

      // --- 👇 核心防沉降：触发特征提取流水线！ ---
      // 在底层写入库后，立刻启动极为狂暴的单机分析流（模糊度方差+MLKit 文字+TFLite 张量），此方法会自动 Update 到行库中。
      final thumbBytes = await entity.thumbnailDataWithSize(const ThumbnailSize(512, 512));
      await extractor.extractFeaturesForImage(idHash, file.absolute.path, thumbBytes);
      
      // 每张图跑完，给系统底层 30 毫秒的时间喘息渲染 UI（让出主线程 Event Loop），彻底告别主页转盘卡死现象！
      await Future.delayed(const Duration(milliseconds: 30));
    } else if (existing.blurScore == 0.0 || existing.semanticVector.isEmpty || existing.tags == null) {
      // 针对之前只有空壳元数据而未能跑过 AI 分析或者早期版本里还没有发明 Tags 翻译规则的历史漏网之鱼，静默重做！
      final thumbBytes = await entity.thumbnailDataWithSize(const ThumbnailSize(512, 512));
      await extractor.extractFeaturesForImage(idHash, file.absolute.path, thumbBytes);
      
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }
}
