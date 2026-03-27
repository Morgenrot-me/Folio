// background_ai_worker.dart
// WorkManager 后台 AI 特征提取调度器。
//
// 架构说明：
//   WorkManager 回调运行在独立进程/Isolate，与前台 Flutter 引擎完全隔离。
//   因此必须在回调内重新初始化数据库、AI 服务（不能复用 Provider 中的实例）。
//
// 任务策略：
//   - OneOffTask：Phase 1 完成后调度一次；任务结束如仍有未分析图片则自动再调度
//   - 约束：requiresBatteryNotLow=true（系统级低电量拦截）+ 运行时检查电量≥50%
//   - 无网络要求（本地 AI，完全离线）
//   - ExistingWorkPolicy.keep：避免重复入队

import 'dart:io';
import 'dart:typed_data';
import 'package:battery_plus/battery_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/native.dart';
import 'app_settings_service.dart';
import '../database/app_database.dart';
import 'feature_extractor_service.dart';
import 'smart_folder_matcher_service.dart';

/// WorkManager 任务名（唯一标识，用于去重和取消）
const kAiAnalysisTaskName = 'ai_analysis_task';

/// WorkManager 任务 tag（用于分组查询）
const kAiAnalysisTaskTag = 'ai_analysis';

/// 后台 AI 分析电量策略（不再硬编码，从 AppSettingsService 读取）
// 保留作为回退默认值（首次安装未设置时使用）
const _kDefaultBatteryThreshold = 50;

/// 每张图片分析间隔（避免持续高负荷，对电量友好）
const _kAnalysisDelay = Duration(milliseconds: 30);

// =============================================================================
// ★ 顶层函数：必须是顶层函数，WorkManager 通过反射调用
// =============================================================================

/// WorkManager 的 Dart 入口。所有后台任务均在此路由。
/// 必须为顶层函数（不能是类的静态方法）。
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('[BgWorker] 任务触发: $taskName');

    if (taskName != kAiAnalysisTaskName) {
      debugPrint('[BgWorker] 未知任务，跳过');
      return true; // 返回 true 告知 WorkManager 任务"成功"（不重试）
    }

    return await _runAiAnalysisTask();
  });
}

// =============================================================================
// 任务主体
// =============================================================================

/// 执行一轮 AI 分析，返回 true 代表任务完成（不再重试）
Future<bool> _runAiAnalysisTask() async {
  // ── Step 1: 读取用户设定的电量策略
  final policy = await AppSettingsService.getBatteryPolicy();
  final battery = Battery();
  final level = await battery.batteryLevel;
  final state = await battery.batteryState;

  debugPrint('[BgWorker] 当前电量: $level%, 状态: $state, 策略: ${policy.label}');

  // chargingOnly：只有充电时才运行
  if (policy == BatteryPolicy.chargingOnly && state != BatteryState.charging) {
    debugPrint('[BgWorker] 策略=仅充电，当前未充电，推迟 2 小时');
    BackgroundAiWorker.schedule(delayMinutes: 120);
    return true;
  }

  // 其他策略：检查电量门槛
  final threshold = policy.minLevel > 0 ? policy.minLevel : _kDefaultBatteryThreshold;
  if (level < threshold && state != BatteryState.charging) {
    debugPrint('[BgWorker] 电量 $level% < $threshold%，推迟 2 小时');
    BackgroundAiWorker.schedule(delayMinutes: 120);
    return true;
  }

  // ── Step 2: 独立初始化数据库（WorkManager Isolate 中不能共享前台实例）
  AppDatabase? database;
  FeatureExtractorService? extractor;
  SmartFolderMatcherService? matcher;

  try {
    final dbDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(dbDir.path, 'smart_gallery.sqlite'));
    database = AppDatabase.fromFile(dbFile);
    extractor = FeatureExtractorService(database);
    matcher = SmartFolderMatcherService(database);

    // ── Step 3: 获取所有未分析图片
    final unanalyzed = await (database.select(database.images)
          ..where((t) => t.isAnalyzed.equals(false)))
        .get();

    debugPrint('[BgWorker] 待分析: ${unanalyzed.length} 张');

    if (unanalyzed.isEmpty) {
      // 全部分析完毕，触发规则匹配后返回
      await matcher.runMatchForAll();
      debugPrint('[BgWorker] 全部分析完成！');
      return true;
    }

    // ── Step 4: 逐张分析，每张前检查电量
    int processed = 0;
    for (final image in unanalyzed) {
      // 每处理 10 张检查一次电量（避免频繁读取）
      if (processed % 10 == 0) {
        final currentLevel = await battery.batteryLevel;
        final currentState = await battery.batteryState;
        // 充电中永远查证通过（无论策略）
        final shouldPause = currentState != BatteryState.charging &&
            (policy == BatteryPolicy.chargingOnly ||
                currentLevel < threshold);
        if (shouldPause) {
          debugPrint('[BgWorker] 分析过程中电量条件不满足（$currentLevel%），暂停并重新调度');
          BackgroundAiWorker.schedule(delayMinutes: 60);
          return true;
        }
      }

      try {
        await extractor.extractFeaturesForImage(image.id, image.filePath);
        processed++;
      } catch (e) {
        debugPrint('[BgWorker] 分析失败 ${image.fileName}: $e');
        // 单张失败不影响整批，继续下一张
      }

      await Future.delayed(_kAnalysisDelay);
    }

    // ── Step 5: 本批分析完毕，检查是否还有剩余（可能有新入库的）
    final remaining = await (database.select(database.images)
          ..where((t) => t.isAnalyzed.equals(false)))
        .get();

    if (remaining.isNotEmpty) {
      debugPrint('[BgWorker] 仍有 ${remaining.length} 张未完成，重新调度');
      BackgroundAiWorker.schedule();
    } else {
      // 全部完成，触发规则匹配
      await matcher.runMatchForAll();
      debugPrint('[BgWorker] 全部分析完成，规则匹配已触发');
    }

    return true;
  } catch (e, stack) {
    debugPrint('[BgWorker] 任务异常: $e\n$stack');
    return false; // 返回 false 让 WorkManager 按退避策略重试
  } finally {
    // 释放资源（TFLite 解释器 + 数据库连接）
    extractor?.dispose();   // 同步释放 TFLite 解释器
    await database?.close();
  }
}

// =============================================================================
// 对外 API（前台代码调用）
// =============================================================================

class BackgroundAiWorker {
  BackgroundAiWorker._();

  /// 初始化 WorkManager（在 main() 中调用，必须在 runApp 之前）
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode, // Debug 模式下强制立即执行（不受 Doze 影响）
    );
    debugPrint('[BgWorker] WorkManager 初始化完成');
  }

  /// 调度一次 AI 分析任务。
  ///
  /// [delayMinutes] 延迟执行的分钟数（0 = 尽快执行）
  /// ExistingWorkPolicy.keep：若同名任务已在队列中，不重复入队
  static Future<void> schedule({int delayMinutes = 0}) async {
    await Workmanager().registerOneOffTask(
      kAiAnalysisTaskName,       // 唯一任务 ID（用于去重）
      kAiAnalysisTaskName,       // task name（传入 callbackDispatcher）
      tag: kAiAnalysisTaskTag,
      existingWorkPolicy: ExistingWorkPolicy.keep,
      initialDelay: Duration(minutes: delayMinutes),
      constraints: Constraints(
        // 系统级低电量保护（约 <15-20% 时暂停）
        requiresBatteryNotLow: true,
        // workmanager 0.5.2 不支持 requiresNetworkConnectivity 参数
        // 默认行为即不要求网络，本地 AI 完全离线运行
      ),
    );
    debugPrint('[BgWorker] 任务已调度，延迟: ${delayMinutes}分钟');
  }

  /// 取消所有 AI 分析后台任务
  static Future<void> cancel() async {
    await Workmanager().cancelByTag(kAiAnalysisTaskTag);
    debugPrint('[BgWorker] 后台任务已取消');
  }
}
