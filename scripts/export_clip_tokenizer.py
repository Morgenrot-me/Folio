"""
export_clip_tokenizer.py
从 open_clip 中提取 MobileCLIP 的 CLIP BPE Tokenizer 词表，
导出为 Dart 可直接加载的 JSON 格式。

生成文件：
  scripts/clip_vocab.json  （约 2MB）
  复制到 frontend/assets/models/clip_vocab.json

使用方式（在 .venv_ml 环境中运行）：
  python scripts\\export_clip_tokenizer.py
"""

import os
import sys
import json
import gzip

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_JSON   = os.path.join(SCRIPT_DIR, 'clip_vocab.json')
ASSETS_DST = os.path.join(SCRIPT_DIR, '..', 'frontend', 'assets', 'models',
                           'clip_vocab.json')

# ─────────────────────────────────────────────────────────────────────────────
# 标准 CLIP bytes_to_unicode 映射（GPT-2 字节级别 BPE）
# ─────────────────────────────────────────────────────────────────────────────
def bytes_to_unicode():
    """
    返回 {byte_int -> unicode_char} 映射。
    CLIP 将所有 256 个字节映射到可打印 Unicode 字符，以避免 OOV。
    """
    bs = (list(range(ord('!'), ord('~') + 1)) +
          list(range(ord('\xa1'), ord('\xac') + 1)) +
          list(range(ord('\xae'), ord('\xff') + 1)))
    cs = list(bs)
    n = 0
    for b in range(256):
        if b not in bs:
            bs.append(b)
            cs.append(256 + n)
            n += 1
    return {b: chr(c) for b, c in zip(bs, cs)}


def build_vocab_from_open_clip():
    """
    从 open_clip 提取 SimpleTokenizer 的内部数据结构。
    返回包含 encoder/bpe_merges/byte_encoder 的 dict。
    """
    try:
        import open_clip
    except ImportError:
        print('[ERROR] open_clip_torch 未安装')
        sys.exit(1)

    print('[1/3] 加载 MobileCLIP-S1 tokenizer...')
    tok = open_clip.get_tokenizer('MobileCLIP-S1')

    # 兼容不同版本 open_clip 的 tokenizer 包装层
    inner = tok
    for attr in ('_tokenizer', 'tokenizer'):
        if hasattr(tok, attr):
            inner = getattr(tok, attr)
            break

    # ── SimpleTokenizer 路径 ──
    if hasattr(inner, 'encoder') and hasattr(inner, 'bpe_ranks'):
        encoder   = dict(inner.encoder)          # str -> int
        bpe_ranks = inner.bpe_ranks              # (str, str) -> int

        merges_ordered = sorted(bpe_ranks.keys(), key=lambda p: bpe_ranks[p])
        merges_list    = [f'{a} {b}' for a, b in merges_ordered]

        byte_enc = {}
        if hasattr(inner, 'byte_encoder'):
            byte_enc = {str(k): v for k, v in inner.byte_encoder.items()}
        else:
            byte_enc = {str(k): v for k, v in bytes_to_unicode().items()}

        print(f'  词表: {len(encoder)} 个 token，merge 规则: {len(merges_list)} 条')
        return {
            'encoder':      encoder,
            'bpe_merges':   merges_list,
            'byte_encoder': byte_enc,
        }

    # ── HFTokenizer 路径（部分 open_clip 版本）──
    print('  未找到 SimpleTokenizer，尝试 HFTokenizer...')
    vocab = {}
    if hasattr(inner, 'get_vocab'):
        vocab = inner.get_vocab()
    elif hasattr(inner, 'vocab'):
        vocab = dict(inner.vocab)

    merges_list = []
    for attr in ('merges', 'bpe_ranks'):
        if hasattr(inner, attr):
            raw = getattr(inner, attr)
            if isinstance(raw, dict):
                merges_list = [f'{a} {b}' for a, b in
                               sorted(raw.keys(), key=lambda p: raw[p])]
            elif isinstance(raw, list):
                merges_list = [f'{a} {b}' for a, b in raw]
            break

    byte_enc = bytes_to_unicode()
    byte_enc = {str(k): v for k, v in byte_enc.items()}

    print(f'  词表: {len(vocab)} token，merge 规则: {len(merges_list)} 条')
    return {
        'encoder':      vocab,
        'bpe_merges':   merges_list,
        'byte_encoder': byte_enc,
    }


def build_vocab_from_bpe_file():
    """
    备用路径：扫描 open_clip 安装包内的 BPE 词表文件并解析。
    文件名包含 'bpe' 且（'vocab' 或 '16e6'）。
    """
    try:
        import open_clip
        pkg_dir = os.path.dirname(open_clip.__file__)
    except ImportError:
        print('[ERROR] open_clip_torch 未安装')
        sys.exit(1)

    vocab_path = None
    for root, _, files in os.walk(pkg_dir):
        for f in files:
            fl = f.lower()
            if 'bpe' in fl and ('vocab' in fl or '16e6' in fl):
                vocab_path = os.path.join(root, f)
                break
        if vocab_path:
            break

    if not vocab_path:
        print('[ERROR] 未找到 BPE 词表文件，请确认 open_clip_torch 已正确安装')
        sys.exit(1)

    print(f'  从文件解析词表：{vocab_path}')

    opener = gzip.open if vocab_path.endswith('.gz') else open
    mode   = 'rt' if vocab_path.endswith('.gz') else 'r'
    with opener(vocab_path, mode, encoding='utf-8') as fp:
        lines = [l.strip() for l in fp if l.strip() and not l.startswith('#')]

    merges_list = []
    for line in lines:
        parts = line.split()
        if len(parts) == 2:
            merges_list.append(f'{parts[0]} {parts[1]}')

    # 重建词表
    byte_enc      = bytes_to_unicode()
    vocab_strings = list(byte_enc.values())
    vocab_strings += [v + '</w>' for v in vocab_strings]  # 词尾标记变体
    for m in merges_list:
        vocab_strings.append(m.replace(' ', ''))
    vocab_strings += ['<|startoftext|>', '
