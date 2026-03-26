// create_folder_screen.dart
// 创建智能过滤文件夹：根据截图/文字检出/清晰度规则创建规则树并落库。
// 修复：
//   - 创建成功后通过 SnackBar 给出明确反馈再 pop
//   - withOpacity → withValues
//   - 清晰度 Slider 改用"%" 标注，UI 描述改为用户语言

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';

class CreateFolderScreen extends StatefulWidget {
  const CreateFolderScreen({super.key});

  @override
  State<CreateFolderScreen> createState() => _CreateFolderScreenState();
}

class _CreateFolderScreenState extends State<CreateFolderScreen> {
  final _nameController = TextEditingController();
  final _uuid = const Uuid();
  bool _isCreating = false; // 防重复提交

  bool _excludeScreenshots = false;
  bool _requireText = false;

  /// 清晰度要求百分比（0 = 不限，100 = 仅最清晰）
  /// 存库时还原为实际拉普拉斯阈值（百分比 × 100，粗略映射）
  double _sharpnessPct = 0.0;

  String _generateId() => _uuid.v4();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveFolder() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入分类名称')),
      );
      return;
    }
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      final db = context.read<AppDatabase>();
      final folderId = _generateId();
      final rootRuleId = _generateId();

      final List<FolderRulesCompanion> rules = [];

      // Root AND 节点
      rules.add(FolderRulesCompanion.insert(
        id: rootRuleId,
        folderId: folderId,
        nodeType: 'AND',
      ));

      if (_excludeScreenshots) {
        rules.add(FolderRulesCompanion.insert(
          id: _generateId(),
          folderId: folderId,
          parentId: drift.Value(rootRuleId),
          nodeType: 'LEAF',
          featureType: const drift.Value('IS_SCREENSHOT'),
          comparator: const drift.Value('=='),
          value: const drift.Value('false'),
        ));
      }

      if (_requireText) {
        rules.add(FolderRulesCompanion.insert(
          id: _generateId(),
          folderId: folderId,
          parentId: drift.Value(rootRuleId),
          nodeType: 'LEAF',
          featureType: const drift.Value('HAS_TEXT'),
          comparator: const drift.Value('=='),
          value: const drift.Value('true'),
        ));
      }

      // 将百分比映射到实际拉普拉斯阈值（×100 粗略对应）
      final blurThreshold = _sharpnessPct * 100;
      if (blurThreshold > 0) {
        rules.add(FolderRulesCompanion.insert(
          id: _generateId(),
          folderId: folderId,
          parentId: drift.Value(rootRuleId),
          nodeType: 'LEAF',
          featureType: const drift.Value('BLUR_SCORE'),
          comparator: const drift.Value('>'),
          value: drift.Value(blurThreshold.toStringAsFixed(1)),
        ));
      }

      await db.transaction(() async {
        await db.into(db.smartFolders).insert(
          SmartFoldersCompanion.insert(
            id: folderId,
            name: _nameController.text.trim(),
            icon: 'folder',
            color: Colors.blue.value,
            rootRuleId: drift.Value(rootRuleId),
            sortOrder: DateTime.now().millisecondsSinceEpoch,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            lastMatchedAt: 0,
          ),
        );
        for (final r in rules) {
          await db.into(db.folderRules).insert(r);
        }
      });

      if (mounted) {
        // 先展示成功反馈再返回
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 「${_nameController.text.trim()}」已创建')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新建智能规则分类'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isCreating
                ? const Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5)))
                : FilledButton.icon(
                    onPressed: _saveFolder,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('创建'),
                  ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: '分类名称',
              hintText: '例如：旅行风景、清晰名片...',
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            '筛选规则（条件同时满足）',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 16),

          // 基础开关规则
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('排除截屏', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('过滤系统截图，只保留相机拍摄的实景照片', style: TextStyle(fontSize: 12)),
                  value: _excludeScreenshots,
                  onChanged: (val) => setState(() => _excludeScreenshots = val),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                SwitchListTile(
                  title: const Text('含有文本', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('适用于发票、文档翻拍、书本、名片扫描等场景', style: TextStyle(fontSize: 12)),
                  value: _requireText,
                  onChanged: (val) => setState(() => _requireText = val),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 清晰度 Slider（百分比）
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('清晰度要求', style: TextStyle(fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _sharpnessPct == 0
                            ? '不限'
                            : '≥ ${_sharpnessPct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: _sharpnessPct,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (val) => setState(() => _sharpnessPct = val),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    _sharpnessPct == 0
                        ? '不限制清晰度，全部图片均可进入此分类。'
                        : '仅保留清晰度前 ${(100 - _sharpnessPct).toStringAsFixed(0)}% 的照片（过滤肉眼可见的模糊/手抖废片）。',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
