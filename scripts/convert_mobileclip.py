"""
convert_mobileclip.py
MobileCLIP（Apple）图像编码器 + 文本编码器 PyTorch → ONNX → TFLite 转换脚本。

同时导出两个编码器：
  - 图像编码器（Vision Encoder）：输入 [1,3,256,256]，输出 512 维语义向量
  - 文本编码器（Text  Encoder）：输入 [1,77] int32 token IDs，输出 512 维语义向量

两者输出在同一 MobileCLIP 语义空间，可直接做余弦相似度搜索。
✅ 不依赖 mobileclip 包，直接使用 open_clip_torch（已安装）加载模型。

支持规格（open_clip_torch 3.3 内置）：
  S1  ~ 25M 参数，推荐
  S2  ~ 35M 参数，精度更高
  B   最大版本

依赖：
  pip install onnx2tf sng4onnx --no-deps

使用方式：
  python scripts\\convert_mobileclip.py --model S1

完成后复制到 frontend/assets/models/：
  scripts/mobileclip_s1_vision.tflite
  scripts/mobileclip_s1_text.tflite
"""

import os
import sys
import shutil
import argparse
import urllib.request

import numpy as np
import onnx
import onnx.helper
import torch

# ── monkey-patch：onnx_graphsurgeon 依赖此函数，新版 onnx 已移除
if not hasattr(onnx.helper, 'float32_to_bfloat16'):
    def _float32_to_bfloat16(val):
        arr = np.asarray(val, dtype=np.float32)
        return (arr.view(np.uint32) >> 16).astype(np.uint16)
    onnx.helper.float32_to_bfloat16 = _float32_to_bfloat16

import onnx2tf

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# 权重直链（Apple 官方 CDN，若超时可手动下载后放到 scripts/ 目录）
# 注：S0 未在 open_clip 中注册，从 S1 开始
_WEIGHT_URLS = {
    'S1': 'https://docs-assets.developer.apple.com/ml-research/datasets/mobileclip/mobileclip_s1.pt',
    'S2': 'https://docs-assets.developer.apple.com/ml-research/datasets/mobileclip/mobileclip_s2.pt',
    'B':  'https://docs-assets.developer.apple.com/ml-research/datasets/mobileclip/mobileclip_b.pt',
}

# open_clip 中注册的模型名（与 open_clip.list_models() 一致）
_CLIP_NAMES = {
    'S1': 'MobileCLIP-S1',
    'S2': 'MobileCLIP-S2',
    'B':  'MobileCLIP-B',
}
# =============================================================================
def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument('--model', default='S1', choices=['S1', 'S2', 'B'],
                   help='MobileCLIP 规格（S1=推荐，S2=更高精度，B=最大，默认 S1）')
    p.add_argument('--input-size', type=int, default=256,
                   help='输入分辨率（MobileCLIP 原始使用 256x256）')
    return p.parse_args()


def download_weights(model: str) -> str:
    """下载 Apple 官方权重（约 30-200 MB）"""
    url = _WEIGHT_URLS[model]
    dst = os.path.join(SCRIPT_DIR, f'mobileclip_{model.lower()}.pt')
    if os.path.exists(dst):
        print(f'[1/4] 权重文件已存在：{dst}，跳过下载')
        return dst

    print(f'[1/4] 正在下载 MobileCLIP-{model} 权重...')
    def _prog(b, bs, total):
        done = min(b * bs, total)
        print(f'\r  {done//1024//1024} / {total//1024//1024} MB',
              end='', flush=True)
    urllib.request.urlretrieve(url, dst, reporthook=_prog)
    print(f'\n  完成 → {dst}')
    return dst


def load_vision_encoder(model: str, weights_path: str, input_size: int):
    """
    加载 MobileCLIP 并提取图像编码器（Vision Encoder）。
    直接使用 open_clip_torch，不需要单独安装 mobileclip 包。
    """
    import open_clip

    clip_name = _CLIP_NAMES[model]
    print(f'[2/4] 用 open_clip 加载 {clip_name}...')

    # open_clip_torch >= 2.24 已内置 MobileCLIP 注册
    try:
        clip_model, _, _ = open_clip.create_model_and_transforms(
            clip_name,
            pretrained=weights_path,
        )
    except Exception as e:
        print(f'\n[ERROR] open_clip 加载失败：{e}')
        print('请确认 open_clip_torch 版本 >= 2.24：')
        print('  pip install -U open_clip_torch')
        sys.exit(1)

    clip_model.eval()
    vision = clip_model.visual
    vision.eval()

    class VisionOnlyModel(torch.nn.Module):
        """
        纯图像编码器包装。
        输入：[1, 3, H, W]，像素值范围 [0, 1]，ImageNet 归一化
        输出：[1, 512]，L2 归一化语义向量
        """
        def __init__(self, visual):
            super().__init__()
            self.visual = visual

        def forward(self, x):
            feat = self.visual(x)
            return torch.nn.functional.normalize(feat, p=2.0, dim=-1)

    model_wrapped = VisionOnlyModel(vision)
    model_wrapped.eval()

    with torch.no_grad():
        dummy = torch.randn(1, 3, input_size, input_size)
        out = model_wrapped(dummy)
        print(f'  图像编码器输出维度：{out.shape}  （应为 [1, 512]）')

    return model_wrapped


def export_onnx(model, input_size: int, model_tag: str) -> str:
    """PyTorch → ONNX"""
    onnx_path = os.path.join(SCRIPT_DIR, f'mobileclip_{model_tag.lower()}_vision.onnx')
    print(f'[3/4] 导出 ONNX → {onnx_path}')

    dummy = torch.randn(1, 3, input_size, input_size)
    torch.onnx.export(
        model, dummy, onnx_path,
        input_names=['image'],
        output_names=['embedding'],
        opset_version=17,
    )
    size_mb = os.path.getsize(onnx_path) / 1024 / 1024
    print(f'  ONNX 写入完成（{size_mb:.1f} MB）')
    return onnx_path


def _ensure_param_json(json_path: str, model_lower: str) -> None:
    """
    确保 onnx2tf 的 param_replacement_file 存在。
    该文件用于绕过 tf.norm(axis=np.int64) 兼容性 bug：
    将 ReduceL2 / linalg_vector_norm 节点的 keepdims 强制为整数 0。
    """
    import json as _json
    if os.path.exists(json_path):
        return  # 已存在（可能是 onnx2tf 自动生成的），直接复用
    payload = {
        "format_version": 1,
        "operations": [
            {
                "op_name": f"node_linalg_vector_norm",
                "param_target": "attributes",
                "param_name": "keepdims",
                "values": 0
            }
        ],
        "_comment": f"Auto-created for {model_lower}: 绕过 axis=np.int64 bug"
    }
    with open(json_path, 'w', encoding='utf-8') as fp:
        _json.dump(payload, fp, ensure_ascii=False, indent=2)
    print(f'  创建 param_replacement_file: {json_path}')


def export_tflite(onnx_path: str, model_tag: str) -> str:
    """ONNX → TFLite（via onnx2tf）"""
    model_lower = model_tag.lower()
    tf_dir = os.path.join(SCRIPT_DIR, f'mobileclip_{model_lower}_tf')
    tflite_out = os.path.join(SCRIPT_DIR,
                              f'mobileclip_{model_lower}_vision.tflite')
    param_json = os.path.join(SCRIPT_DIR, f'mobileclip_{model_lower}_vision_auto.json')

    print(f'[4/4] onnx2tf 转换 TFLite（约 1-3 分钟）...')
    os.makedirs(tf_dir, exist_ok=True)
    _ensure_param_json(param_json, model_lower)

    onnx2tf.convert(
        input_onnx_file_path=onnx_path,
        output_folder_path=tf_dir,
        non_verbose=True,
        param_replacement_file=param_json,
    )

    # 查找输出 .tflite
    src = None
    for fname in os.listdir(tf_dir):
        if fname.endswith('_float32.tflite') or fname.endswith('.tflite'):
            src = os.path.join(tf_dir, fname)
            break

    if src is None:
        print(f'[ERROR] 未找到 .tflite 输出，请检查目录：{tf_dir}')
        sys.exit(1)

    shutil.copy2(src, tflite_out)
    size_mb = os.path.getsize(tflite_out) / 1024 / 1024
    print(f'  TFLite 写入完成 → {tflite_out}（{size_mb:.1f} MB）')
    return tflite_out


# =============================================================================
# 文本编码器导出
# =============================================================================

class TextOnlyModel(torch.nn.Module):
    """
    MobileCLIP 纯文本编码器包装。
    输入：[1, 77] int32 token IDs（CLIP BPE tokenizer 输出）
    输出：[1, 512]，L2 归一化文本语义向量
    与 VisionOnlyModel 输出在同一语义空间，可直接做余弦相似度。
    """
    def __init__(self, clip_model):
        super().__init__()
        self.token_embedding   = clip_model.token_embedding
        self.positional_embedding = clip_model.positional_embedding
        self.transformer       = clip_model.transformer
        self.ln_final          = clip_model.ln_final
        self.text_projection   = clip_model.text_projection
        # 预计算因果注意力掩码（bake-in，避免 ONNX 追踪为输入）
        ctx_len = 77
        mask = torch.empty(ctx_len, ctx_len).fill_(float('-inf')).triu_(1)
        self.register_buffer('attn_mask', mask)

    def forward(self, text: torch.Tensor) -> torch.Tensor:
        # text: [B, 77] int64
        x = self.token_embedding(text).float()      # [B, 77, d_model]
        x = x + self.positional_embedding[:x.shape[1]]
        x = x.permute(1, 0, 2)                     # NLD -> LND
        x = self.transformer(x, attn_mask=self.attn_mask)
        x = x.permute(1, 0, 2)                     # LND -> NLD
        x = self.ln_final(x).float()
        # 取 EOT（end-of-text）位置的特征 —— EOT token ID 是序列中最大值
        eot_pos = text.argmax(dim=-1)               # [B]
        x = x[torch.arange(x.shape[0]), eot_pos] @ self.text_projection
        return torch.nn.functional.normalize(x, p=2.0, dim=-1)


def load_text_encoder(model_tag: str, weights_path: str):
    """从已下载的权重文件加载 MobileCLIP 文本编码器。"""
    import open_clip
    clip_name = _CLIP_NAMES[model_tag]
    print(f'[T-1] 加载文本编码器来自 {clip_name}...')
    clip_model, _, _ = open_clip.create_model_and_transforms(
        clip_name, pretrained=weights_path,
    )
    clip_model.eval()
    text_model = TextOnlyModel(clip_model)
    text_model.eval()
    # 验证输出维度
    with torch.no_grad():
        dummy = torch.zeros(1, 77, dtype=torch.long)
        dummy[0, 0] = 49406  # SOT
        dummy[0, 1] = 49407  # EOT（最简单的有效序列）
        out = text_model(dummy)
        print(f'  文本编码器输出维度：{out.shape}  （应为 [1, 512]）')
    return text_model


def export_text_onnx(text_model, model_tag: str) -> str:
    """文本编码器 PyTorch → ONNX"""
    onnx_path = os.path.join(SCRIPT_DIR, f'mobileclip_{model_tag.lower()}_text.onnx')
    print(f'[T-2] 导出文本编码器 ONNX → {onnx_path}')
    dummy = torch.zeros(1, 77, dtype=torch.long)
    dummy[0, 0] = 49406
    dummy[0, 1] = 49407
    torch.onnx.export(
        text_model, dummy, onnx_path,
        input_names=['token_ids'],
        output_names=['text_embedding'],
        opset_version=17,
    )
    size_mb = os.path.getsize(onnx_path) / 1024 / 1024
    print(f'  ONNX 写入完成（{size_mb:.1f} MB）')
    return onnx_path


def export_text_tflite(onnx_path: str, model_tag: str) -> str:
    """文本编码器 ONNX → TFLite（via onnx2tf）"""
    model_lower = model_tag.lower()
    tf_dir    = os.path.join(SCRIPT_DIR, f'mobileclip_{model_lower}_text_tf')
    tflite_out = os.path.join(SCRIPT_DIR, f'mobileclip_{model_lower}_text.tflite')
    param_json = os.path.join(SCRIPT_DIR, f'mobileclip_{model_lower}_text_auto.json')
    print(f'[T-3] onnx2tf 转换文本编码器 TFLite（约 1-2 分钟）...')
    os.makedirs(tf_dir, exist_ok=True)
    _ensure_param_json(param_json, model_lower)
    onnx2tf.convert(
        input_onnx_file_path=onnx_path,
        output_folder_path=tf_dir,
        non_verbose=True,
        param_replacement_file=param_json,
    )
    src = None
    for fname in os.listdir(tf_dir):
        if fname.endswith('.tflite'):
            src = os.path.join(tf_dir, fname)
            break
    if src is None:
        print(f'[ERROR] 未找到文本编码器 .tflite，请检查目录：{tf_dir}')
        sys.exit(1)
    shutil.copy2(src, tflite_out)
    size_mb = os.path.getsize(tflite_out) / 1024 / 1024
    print(f'  TFLite 写入完成 → {tflite_out}（{size_mb:.1f} MB）')
    return tflite_out


def main():
    args = parse_args()
    model_tag  = args.model
    input_size = args.input_size

    # ── 1. 下载权重（图像 + 文本共享同一权重文件）
    weights_path = download_weights(model_tag)

    # ── 2a. 图像编码器：加载 → ONNX → TFLite
    vision_model  = load_vision_encoder(model_tag, weights_path, input_size)
    vision_onnx   = export_onnx(vision_model, input_size, model_tag)
    vision_tflite = export_tflite(vision_onnx, model_tag)

    # ── 2b. 文本编码器：加载 → ONNX → TFLite
    text_model    = load_text_encoder(model_tag, weights_path)
    text_onnx     = export_text_onnx(text_model, model_tag)
    text_tflite   = export_text_tflite(text_onnx, model_tag)

    # ── 完成提示
    tag = model_tag.lower()
    print()
    print('=' * 60)
    print('✅ 全部完成！请将以下文件复制到 frontend/assets/models/：')
    print(f'  copy "{vision_tflite}" frontend\\assets\\models\\mobileclip_{tag}_vision.tflite')
    print(f'  copy "{text_tflite}"   frontend\\assets\\models\\mobileclip_{tag}_text.tflite')
    print()
    print('然后运行 export_clip_tokenizer.py 导出词表文件。')
    print('=' * 60)


if __name__ == '__main__':
    main()

