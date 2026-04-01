// clip_tokenizer.dart
// CLIP BPE Tokenizer 的 Dart 实现，用于将文字编码为 [1, 77] int32 token ID 序列。
// 算法与 OpenAI CLIP 原版完全兼容：
//   1. UTF-8 字节级别预处理（bytes_to_unicode 映射）
//   2. GPT-2 风格 BPE merge 规则迭代
//   3. 首尾加 SOT(49406) / EOT(49407)，padding 补 0 至长度 77
//
// 词表来源：assets/models/clip_vocab.json
// 该文件由 scripts/export_clip_tokenizer.py 生成

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// CLIP BPE Tokenizer
class ClipTokenizer {
  // SOT = start-of-text, EOT = end-of-text（CLIP 固定值）
  static const int _sotToken = 49406;
  static const int _eotToken = 49407;
  static const int _maxLen   = 77;

  /// token_string -> token_id 映射（词表）
  final Map<String, int> _encoder;

  /// BPE merge 规则：键 = "a b"，值 = 优先级（越低越先合并）
  final Map<String, int> _bpeRanks;

  /// byte -> unicode char 映射（GPT-2 字节级别编码）
  final Map<int, String> _byteEncoder;

  ClipTokenizer._({
    required Map<String, int> encoder,
    required Map<String, int> bpeRanks,
    required Map<int, String> byteEncoder,
  })  : _encoder     = encoder,
        _bpeRanks    = bpeRanks,
        _byteEncoder = byteEncoder;

  // ── 工厂：从 assets 异步加载 ─────────────────────────────────────────────

  static ClipTokenizer? _instance;

  /// 加载（单例，首次调用时从 assets 读取 JSON）
  static Future<ClipTokenizer> load() async {
    if (_instance != null) return _instance!;

    final raw  = await rootBundle.loadString('assets/models/clip_vocab.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;

    final encoderRaw  = (data['encoder']      as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));
    final mergesRaw   = (data['bpe_merges']   as List<dynamic>)
        .cast<String>();
    final byteEncRaw  = (data['byte_encoder'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(int.parse(k), v as String));

    final bpeRanks = <String, int>{
      for (var i = 0; i < mergesRaw.length; i++) mergesRaw[i]: i
    };

    _instance = ClipTokenizer._(
      encoder:     encoderRaw,
      bpeRanks:    bpeRanks,
      byteEncoder: byteEncRaw,
    );
    debugPrint('ClipTokenizer: 词表 ${encoderRaw.length} tokens, '
        'BPE rules ${bpeRanks.length}');
    return _instance!;
  }

  // ── 公开 API ─────────────────────────────────────────────────────────────

  /// 将任意文字编码为长度 77 的 Int32List（CLIP 标准格式）
  /// 首位 = SOT(49406)，末位 = EOT(49407)，其余补 0
  Int32List encode(String text) {
    final tokens = _tokenize(text);
    final result = Int32List(_maxLen); // 全 0 初始化（padding）
    result[0] = _sotToken;
    // 最多 75 个内容 token（77 - SOT - EOT）
    final contentLen = tokens.length.clamp(0, _maxLen - 2);
    for (var i = 0; i < contentLen; i++) {
      result[i + 1] = tokens[i];
    }
    result[contentLen + 1] = _eotToken;
    return result;
  }

  // ── 内部实现 ──────────────────────────────────────────────────────────────

  /// 文字 → token ID 列表（不含 SOT/EOT）
  List<int> _tokenize(String text) {
    // 1. 文本清洗：小写+合并空白
    final cleaned = text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

    // 2. 按空白/标点分词（简化版，与 CLIP SimpleTokenizer 基本一致）
    final pat = RegExp(
        r"(?i)<\|startoftext\|>|<\|endoftext\|>|'s|'t|'re|'ve|'m|'ll|'d"
        r'|\p{L}+|\p{N}|[^\s\p{L}\p{N}]+',
        unicode: true);
    final words = pat.allMatches(cleaned).map((m) => m.group(0)!).toList();

    final ids = <int>[];
    for (final word in words) {
      // 3. UTF-8 字节级别 → BPE tokens
      final byteTokens = _encodeBytes(word);
      final merged     = _bpe(byteTokens);
      for (final t in merged) {
        final id = _encoder[t];
        if (id != null) ids.add(id);
      }
    }
    return ids;
  }

  /// 将一个 word 的 UTF-8 字节映射到 byteEncoder 字符序列
  List<String> _encodeBytes(String word) {
    final bytes = utf8.encode(word);
    return bytes
        .map((b) => _byteEncoder[b] ?? String.fromCharCode(b))
        .toList();
  }

  /// BPE 算法：对 token 列表迭代合并，直到无可合并的 pair
  List<String> _bpe(List<String> tokens) {
    if (tokens.length <= 1) return tokens;

    var word = List<String>.from(tokens);

    while (true) {
      // 找出当前 word 中优先级最高（rank 最小）的相邻 pair
      int?    bestRank;
      String? bestPair;
      int?    bestIdx;

      for (var i = 0; i < word.length - 1; i++) {
        final pair = '${word[i]} ${word[i + 1]}';
        final rank = _bpeRanks[pair];
        if (rank != null && (bestRank == null || rank < bestRank)) {
          bestRank = rank;
          bestPair = pair;
          bestIdx  = i;
        }
      }

      if (bestPair == null) break;

      // 合并所有出现该 pair 的位置
      final newWord = <String>[];
      var i = 0;
      while (i < word.length) {
        if (i < word.length - 1 &&
            '${word[i]} ${word[i + 1]}' == bestPair) {
          newWord.add('${word[i]}${word[i + 1]}');
          i += 2;
        } else {
          newWord.add(word[i]);
          i++;
        }
      }
      word = newWord;
    }

    return word;
  }
}
