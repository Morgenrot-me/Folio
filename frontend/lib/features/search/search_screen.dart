// search_screen.dart
// 语义搜索页：用户输入任意文字描述，通过 MobileCLIP 文本编码器在图库中检索语义相似图片。
// 功能：
//   - 搜索框 + 防抖（600ms）
//   - 未搜索时显示示例词组提示
//   - 搜索中显示加载动画
//   - 结果以 3 列网格展示，每张图标注相似度百分比
//   - 空结果态有友善提示
//   - 点击图片进入全屏详情页（含 Hero 动画）
//   - 若 clipVector 未就绪（模型待下载），显示引导提示

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/semantic_search_service.dart';
import '../gallery/image_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode  = FocusNode();

  List<SemanticSearchResult> _results  = [];
  bool   _isSearching  = false;
  bool   _hasSearched  = false;
  String _lastQuery    = '';
  int    _unindexed    = -1; // -1 = 尚未检查

  Timer? _debounce;

  // 搜索示例，引导用户发现功能
  static const _examples = [
    '🌊 海边度假',
    '🐶 可爱的狗狗',
    '🌅 美丽的日落',
    '🍜 美食料理',
    '🏔 雪山风景',
    '👨‍👩‍👧 一家人',
    '🌸 花卉植物',
    '🏙 城市夜景',
  ];

  @override
  void initState() {
    super.initState();
    // 检查 clipVector 就绪情况
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkIndexStatus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkIndexStatus() async {
    final svc = context.read<SemanticSearchService>();
    final count = await svc.countUnindexed();
    if (mounted) setState(() => _unindexed = count);
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() { _results = []; _hasSearched = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(query));
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed == _lastQuery || trimmed.isEmpty) return;
    _lastQuery = trimmed;
    if (!mounted) return;
    setState(() { _isSearching = true; _hasSearched = true; });
    try {
      final svc     = context.read<SemanticSearchService>();
      final results = await svc.searchByText(trimmed, topK: 60);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语义搜索'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: _buildSearchBar(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _controller,
        focusNode:  _focusNode,
        onChanged:  _onQueryChanged,
        onSubmitted: (q) { _debounce?.cancel(); _search(q); },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '用自然语言描述图片内容...',
          prefixIcon: const Icon(Icons.image_search_rounded),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _controller.clear();
                        setState(() { _results = []; _hasSearched = false; _lastQuery = ''; });
                      },
                    )
                  : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // clipVector 未就绪提示（-1代表检查中，>0代表有未索引图片）
    if (_unindexed > 0) {
      return _buildNotReadyBanner();
    }

    if (!_hasSearched) return _buildHintGrid();
    if (_isSearching)   return _buildLoadingState();
    if (_results.isEmpty) return _buildEmptyState();
    return _buildResultsGrid();
  }

  /// 模型文件缺失或向量未就绪时的提示横幅
  Widget _buildNotReadyBanner() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$_unindexed 张图片尚未生成语义向量。\n'
                  '请在「大盘总览」触发扫描后，等待后台 AI 分析完成。',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildHintGrid()),
      ],
    );
  }

  /// 未搜索时的示例词组网格
  Widget _buildHintGrid() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('试着搜索...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  )),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _examples.map((ex) {
              return ActionChip(
                label: Text(ex, style: const TextStyle(fontSize: 13)),
                onPressed: () {
                  _controller.text = ex.substring(2).trim(); // 去掉 emoji
                  _search(_controller.text);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
      itemCount: 12,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 72,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 20),
            Text('未找到相关图片',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    )),
            const SizedBox(height: 8),
            Text('换个描述方式试试，比如换成英文关键词',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsGrid() {
    final images = _results.map((r) => r.image).toList();
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        final img    = result.image;
        final pct    = (result.similarity * 100).toStringAsFixed(0);
        final tag    = 'search_${img.id}';

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImageDetailScreen(
                images: images, initialIndex: index, heroTag: tag,
              ),
            ),
          ),
          child: Hero(
            tag: tag,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(img.filePath),
                    fit: BoxFit.cover,
                    cacheWidth: 300,
                    errorBuilder: (_, __, ___) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  ),
                ),
                // 相似度角标
                Positioned(
                  right: 4, bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$pct%',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
