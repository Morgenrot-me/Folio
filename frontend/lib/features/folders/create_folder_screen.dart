// create_folder_screen.dart
// 创建智能过滤文件夹，支持以下规则组合：
//   - 截图/文字/清晰度 基础规则
//   - AI 语义标签（SEMANTIC_LABEL）多选筛选，支持场景+内容两大类
// 规则结构：
//   AND（根）
//   ├── IS_SCREENSHOT / HAS_TEXT / BLUR_SCORE（可选）
//   └── OR（AI 标签组，若用户至少选了一个标签）
//       ├── SEMANTIC_LABEL CONTAINS "海边"
//       └── SEMANTIC_LABEL CONTAINS "海滩"

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';

// ── 预设 AI 标签分组 ──────────────────────────────────────────────────────────

/// 场景类标签（主要来自 Places365）
const _kSceneTags = [
  '海边', '海滩', '海岸', '山', '雪山', '森林', '峡谷', '沙漠',
  '街道', '广场', '公园', '桥梁', '港口', '机场',
  '餐厅', '咖啡厅', '酒吧', '超市', '商场', '图书馆',
  '卧室', '客厅', '厨房', '浴室', '办公室', '教室',
  '操场', '游泳池', '体育馆', '海滨别墅',
];

/// 内容/物体类标签（主要来自 ML Kit）
const _kContentTags = [
  '人物', '自拍', '孩子', '人群',
  '狗', '猫', '鸟', '动物',
  '食物', '水果', '蔬菜', '甜品', '饮料',
  '汽车', '摩托车', '自行车',
  '花卉', '树木', '植物',
  '建筑', '天空', '日落',
  '运动', '舞蹈', '表演',
];

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

  /// 当前已选中的 AI 语义标签集合
  final Set<String> _selectedTags = {};

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

      // ── Root AND 节点 ────────────────────────────────────────────────────
      rules.add(FolderRulesCompanion.insert(
        id: rootRuleId,
        folderId: folderId,
        nodeType: 'AND',
      ));

      // ── 基础规则：截图排除 ───────────────────────────────────────────────
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

      // ── 基础规则：含文字 ─────────────────────────────────────────────────
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

      // ── 基础规则：清晰度 ─────────────────────────────────────────────────
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

      // ── AI 语义标签规则：OR 节点 + SEMANTIC_LABEL LEAF ──────────────────
      // 若用户至少选了一个标签，挂一个 OR 节点，每个标签对应一个 LEAF
      if (_selectedTags.isNotEmpty) {
        final orNodeId = _generateId();
        rules.add(FolderRulesCompanion.insert(
          id: orNodeId,
          folderId: folderId,
          parentId: drift.Value(rootRuleId),
          nodeType: 'OR',
        ));
        for (final tag in _selectedTags) {
          rules.add(FolderRulesCompanion.insert(
            id: _generateId(),
            folderId: folderId,
            parentId: drift.Value(orNodeId),
            nodeType: 'LEAF',
            featureType: const drift.Value('SEMANTIC_LABEL'),
            comparator: const drift.Value('CONTAINS'),
            value: drift.Value(tag),
          ));
        }
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

          const SizedBox(height: 24),

          // ── AI 语义标签筛选 ──────────────────────────────────────────────
          _buildTagSection(context),
        ],
      ),
    );
  }

  /// AI 语义标签选择区块（场景类 + 内容类，多选 FilterChip）
  Widget _buildTagSection(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行：标签计数徽章
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI 标签筛选', style: TextStyle(fontWeight: FontWeight.w500)),
              if (_selectedTags.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '已选 ${_selectedTags.length} 个',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '选中后，图片 AI 标签含任一选中词则匹配（OR 逻辑）',
            style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),

          // 场景类标签
          Text('场景',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primary)),
          const SizedBox(height: 8),
          _buildChipGroup(_kSceneTags),

          const SizedBox(height: 16),

          // 内容/物体类标签
          Text('内容与物体',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primary)),
          const SizedBox(height: 8),
          _buildChipGroup(_kContentTags),

          // 清空按钮（有选中时显示）
          if (_selectedTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _selectedTags.clear()),
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('清空'),
                style: TextButton.styleFrom(
                  foregroundColor: onSurface.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 渲染一组标签的 FilterChip 流式布局
  Widget _buildChipGroup(List<String> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        final selected = _selectedTags.contains(tag);
        return FilterChip(
          label: Text(tag),
          selected: selected,
          onSelected: (val) {
            setState(() {
              if (val) {
                _selectedTags.add(tag);
              } else {
                _selectedTags.remove(tag);
              }
            });
          },
          selectedColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          checkmarkColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
          ),
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
            width: selected ? 1.5 : 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          showCheckmark: true,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}
