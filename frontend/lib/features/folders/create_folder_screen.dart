// create_folder_screen.dart
// 创建智能过滤文件夹：根据截图/文字检出/模糊度等规则条件创建规则树并落库。
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

  bool _excludeScreenshots = false;
  bool _requireText = false;
  double _minBlurScore = 0.0;

  /// 生成每次唯一的 UUID v4（无碰撞）
  String _generateId() => _uuid.v4();

  void _saveFolder() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入分类名称')),
      );
      return;
    }

    final db = context.read<AppDatabase>();
    final folderId = _generateId();
    final rootRuleId = _generateId();

    final List<FolderRulesCompanion> rules = [];
    
    // Root AND Node (这是顶级过滤门卫，一切条件都得在 AND 内满足)
    rules.add(FolderRulesCompanion.insert(
      id: rootRuleId,
      folderId: folderId,
      nodeType: 'AND',
    ));

    // 叶子组件条件：是否排除截屏？
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
    
    // 叶子组件条件：是否强制图片内包含有效文字？
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

    // 叶子组件条件：滑块筛选的最模糊临界点
    if (_minBlurScore > 0) {
      rules.add(FolderRulesCompanion.insert(
        id: _generateId(),
        folderId: folderId,
        parentId: drift.Value(rootRuleId),
        nodeType: 'LEAF',
        featureType: const drift.Value('BLUR_SCORE'),
        comparator: const drift.Value('>'),
        value: drift.Value(_minBlurScore.toStringAsFixed(1)),
      ));
    }

    // 数据库事务原子性组装提交
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
        )
      );
      
      for (final r in rules) {
        await db.into(db.folderRules).insert(r);
      }
    });

    if (mounted) {
      Navigator.pop(context);
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
            child: FilledButton.icon(
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
          
          Text('筛选规则池 (要求同时符合)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20)
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('自动丢弃手机截屏', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('过滤掉系统快捷键截图，只保留实体镜头捕获的光影相片', style: TextStyle(fontSize: 12)),
                  value: _excludeScreenshots,
                  onChanged: (val) => setState(() => _excludeScreenshots = val),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                
                SwitchListTile(
                  title: const Text('相片必须含有文本', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('极度适用于发票、文档翻拍、书本片段的高精度文字流归约', style: TextStyle(fontSize: 12)),
                  value: _requireText,
                  onChanged: (val) => setState(() => _requireText = val),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('相片清晰度底层强制干预', style: TextStyle(fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Text(
                        _minBlurScore == 0 ? '全盘接收' : '> ${_minBlurScore.toStringAsFixed(0)}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: _minBlurScore,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (val) => setState(() => _minBlurScore = val),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    _minBlurScore == 0 
                      ? '只要进入此规则引擎，相片不论糊的如何拉胯都照常展示。' 
                      : '低于此拉普拉斯锐度分值的照片（如运动时手抖的废片、对焦失败的模糊图）将被这套规则自动拦截屏蔽。',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5),
                  ),
                ),
              ],
            )
          )
        ],
      ),
    );
  }
}
