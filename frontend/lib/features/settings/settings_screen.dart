// settings_screen.dart
// 应用设置页面：
//   1. 后台 AI 分析电量策略（仅充电 / ≥20% / ≥50% / ≥80%）
//   2. 后台权限引导（电池优化豁免、自启动说明）
//   3. 隐私说明（纯本地工作 + 建议断网）

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import '../../core/services/app_settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  BatteryPolicy _batteryPolicy = BatteryPolicy.level50;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final policy = await AppSettingsService.getBatteryPolicy();
    if (mounted) setState(() => _batteryPolicy = policy);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('应用设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [

          // ── 第一块：后台 AI 分析 ─────────────────────────────────────────
          _SectionHeader(icon: Icons.auto_awesome_rounded, title: '后台 AI 分析'),
          _SettingsCard(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                '最低电量门槛',
                style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                '后台 AI 分析只在以下条件满足时自动运行。\n调低门槛可加快分析速度，调高门槛更省电。',
                style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55)),
              ),
            ),
            // 4 个选项的排列
            ...BatteryPolicy.values.map((policy) => RadioListTile<BatteryPolicy>(
                  value: policy,
                  groupValue: _batteryPolicy,
                  title: Row(
                    children: [
                      Icon(
                        _policyIcon(policy),
                        size: 18,
                        color: _batteryPolicy == policy
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Text(policy.label,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: _batteryPolicy == policy
                                ? FontWeight.w600
                                : FontWeight.normal,
                          )),
                    ],
                  ),
                  activeColor: cs.primary,
                  dense: true,
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _batteryPolicy = v);
                    await AppSettingsService.setBatteryPolicy(v);
                  },
                )),
          ]),

          const SizedBox(height: 20),

          // ── 第二块：后台权限引导 ─────────────────────────────────────────
          _SectionHeader(icon: Icons.battery_charging_full_rounded, title: '后台运行权限'),
          _SettingsCard(children: [
            // 电池优化豁免
            _GuideItem(
              icon: Icons.battery_saver_outlined,
              title: '关闭电池优化限制',
              subtitle: '国内手机（小米 / 华为 / OPPO / vivo 等）默认限制后台进程。'
                  '设为"无限制"可确保 App 被关闭后继续 AI 分析。',
              buttonLabel: '去关闭',
              onTap: () => AppSettings.openAppSettings(
                  type: AppSettingsType.batteryOptimization),
            ),

            const Divider(indent: 16, endIndent: 16, height: 1),

            // 自启动权限
            _GuideItem(
              icon: Icons.restart_alt_rounded,
              title: '开启自启动权限',
              subtitle: '部分机型（小米 MIUI / 魅族 / 华为）需要手动授予自启动权限，'
                  'WorkManager 才能在手机重启后恢复后台任务。\n'
                  '路径通常在：设置 → 应用管理 → 本应用 → 自启动。',
              buttonLabel: '去设置',
              onTap: () => AppSettings.openAppSettings(
                  type: AppSettingsType.settings),
            ),
          ]),

          const SizedBox(height: 20),

          // ── 第三块：隐私与网络 ──────────────────────────────────────────
          _SectionHeader(icon: Icons.lock_outline_rounded, title: '隐私与网络'),
          _SettingsCard(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.verified_user_rounded,
                      color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('本应用 100% 本地运行',
                      style: tt.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                '• 所有 AI 模型运行在您的设备上，不调用任何云端 API\n'
                '• 图片和分析结果仅存储在本地数据库（无上传）\n'
                '• 不收集任何用户行为数据或使用统计\n\n'
                '对隐私要求较高的用户可在系统网络设置中禁止本 App 联网，'
                '不会影响任何功能。',
                style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                    height: 1.6),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.wifi_off_rounded, size: 16),
                label: const Text('禁止本应用联网'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => AppSettings.openAppSettings(
                    type: AppSettingsType.dataRoaming),
              ),
            ),
          ]),

          const SizedBox(height: 32),

          // 版本信息占位
          Center(
            child: Text(
              'Folio · 智能图库  v1.0.0',
              style: tt.bodySmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.3)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _policyIcon(BatteryPolicy p) {
    switch (p) {
      case BatteryPolicy.chargingOnly:
        return Icons.power_rounded;
      case BatteryPolicy.level20:
        return Icons.battery_2_bar_rounded;
      case BatteryPolicy.level50:
        return Icons.battery_4_bar_rounded;
      case BatteryPolicy.level80:
        return Icons.battery_6_bar_rounded;
    }
  }
}

// =============================================================================
// 通用小组件
// =============================================================================

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _GuideItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20,
                color: cs.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: tt.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      height: 1.5,
                    )),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: Text(buttonLabel),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  onPressed: onTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
