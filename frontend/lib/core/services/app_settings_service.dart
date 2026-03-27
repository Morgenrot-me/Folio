// app_settings_service.dart
// 用户设置持久化服务（SharedPreferences 封装）。
//
// 管理以下设置项：
//   - minBatteryLevel: 后台 AI 分析最低电量门槛（0=仅充电, 20, 50, 80）
//     0 表示"仅在充电时运行"

import 'package:shared_preferences/shared_preferences.dart';

/// 后台 AI 分析电量策略
enum BatteryPolicy {
  /// 仅在充电时运行
  chargingOnly(label: '仅在充电时', minLevel: 0),
  /// 电量 ≥ 20% 时运行
  level20(label: '≥ 20%', minLevel: 20),
  /// 电量 ≥ 50% 时运行（默认）
  level50(label: '≥ 50%（推荐）', minLevel: 50),
  /// 电量 ≥ 80% 时运行（省电优先）
  level80(label: '≥ 80%', minLevel: 80);

  const BatteryPolicy({required this.label, required this.minLevel});
  final String label;
  /// 最低电量百分比；0 表示"仅充电时"
  final int minLevel;
}

class AppSettingsService {
  AppSettingsService._();

  static const _keyBatteryPolicy = 'battery_policy';

  // ===========================================================================
  // 电量策略
  // ===========================================================================

  /// 读取用户设定的电量策略，默认 level50
  static Future<BatteryPolicy> getBatteryPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyBatteryPolicy);
    return BatteryPolicy.values.firstWhere(
      (e) => e.name == name,
      orElse: () => BatteryPolicy.level50,
    );
  }

  /// 保存电量策略
  static Future<void> setBatteryPolicy(BatteryPolicy policy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBatteryPolicy, policy.name);
  }
}
