"""
convert_mobileclip.py
MobileCLIP（Apple）图像编码器 PyTorch → ONNX → TFLite 转换脚本。

只导出 图像编码器（Vision Encoder），输出 512 维语义向量，
用于图片相似度搜索和零样本分类。文本编码器在移动端不需要。

支持模型规格：
  S0 ~ 11M 图像编码器参数，推荐首选（最小最快）
  S1 ~ 25M
  S2 ~ 35M

依赖安装：
  pip install torch torchvision onnx onnx2tf sng4onnx
  pip install open_clip_torch timm            # MobileCLIP base 依赖
  pip install git+https://github.com/apple/ml-mobileclip.git

权重下载（官方提供）：
  MobileCLIP-S0: https://docs-assets.developer.apple.com/ml-research/datasets/mobileclip/mobileclip_s0.pt
  MobileCLIP-S1: https://docs-assets.developer.apple.com/ml-research/datasets/mobileclip/mobileclip_s1.pt
  MobileCLIP-S2: https://docs-assets.developer.apple.com/ml-research/datasets/mobileclip/mobileclip_s2.pt

使用方式：
  python scripts\\convert_mobileclip.py --model S0
  python scripts\\convert_mobileclip.py --model S1   # 更高精度

完成后复制到 frontend/assets/models/：
  scripts/mobileclip_s0_vision.tflite
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

# =============================================================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# 官方权重直链（Apple CDN）
_WEIGHT_URLS = {
    'S0': 'https://docs-assets.developer.apple.com/ml-research/datasets/mobileclip/mobileclip_s0.pt',
    'S1': 'https://docs-assets.developer.apple.com/ml-research/datasets/mobileclip/mobileclip_s1.pt',
    'S2': 'https://docs-assets.developer.apple.com/ml-research/datasets/mobileclip/mobileclip_s2.pt',
    'B':  'https://docs-assets.developer.apple.com/ml-research/datasets/mobileclip/mobileclip_b.pt',
}

# MobileCLIP 配置名称（对应 open_clip 中注册的名字）
_CLIP_NAMES = {
    'S0': 'mobileclip_s0',
    'S1': 'mobileclip_s1',
    'S2': 'mobileclip_s2',
    'B':  'mobileclip_b',
}

# =============================================================================
def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument('--model', default='S0', choices=['S0', 'S1', 'S2', 'B'],
                   help='MobileCLIP 规格（S0=最小最快，S2=精度最高，默认 S0）')
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
    返回封装好的纯图像编码模块。
    """
    try:
        import mobileclip
    except ImportError:
        print('[ERROR] 请先安装 MobileCLIP：')
        print('  pip install git+https://github.com/apple/ml-mobileclip.git')
        sys.exit(1)

    clip_name = _CLIP_NAMES[model]
    print(f'[2/4] 加载 MobileCLIP-{model}（{clip_name}）...')

    # MobileCLIP 通过 open_clip 接口加载
    import open_clip
    clip_model, _, preprocess = open_clip.create_model_and_transforms(
        clip_name,
        pretrained=weights_path,
    )
    clip_model.eval()

    # 只要图像编码器（visual）
    vision = clip_model.visual
    vision.eval()

    # 封装：normalize + encode
    class VisionOnlyModel(torch.nn.Module):
        """
        纯图像编码器包装。
        输入：[B, 3, H, W]，像素值范围 [0, 1]，已做 ImageNet 归一化
        输出：[B, 512]，L2 归一化后的语义向量
        """
        def __init__(self, visual):
            super().__init__()
            self.visual = visual

        def forward(self, x):
            features = self.visual(x)
            # L2 归一化（与 open_clip 保持一致）
            features = features / features.norm(dim=-1, keepdim=True).clamp(min=1e-6)
            return features

    model_wrapped = VisionOnlyModel(vision)
    model_wrapped.eval()

    # 输出维度
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
        # 动态 batch（TFLite 转换时会固定为 batch=1）
        dynamic_axes={'image': {0: 'batch'}, 'embedding': {0: 'batch'}},
        opset_version=14,   # MobileCLIP 用了 GELU/SiLU，需要 >= 14
    )
    size_mb = os.path.getsize(onnx_path) / 1024 / 1024
    print(f'  ONNX 写入完成（{size_mb:.1f} MB）')
    return onnx_path


def export_tflite(onnx_path: str, model_tag: str) -> str:
    """ONNX → TFLite（via onnx2tf）"""
    tf_dir = os.path.join(SCRIPT_DIR, f'mobileclip_{model_tag.lower()}_tf')
    tflite_out = os.path.join(SCRIPT_DIR,
                              f'mobileclip_{model_tag.lower()}_vision.tflite')

    print(f'[4/4] onnx2tf 转换 TFLite（约 1-3 分钟）...')
    os.makedirs(tf_dir, exist_ok=True)

    onnx2tf.convert(
        input_onnx_file_path=onnx_path,
        output_folder_path=tf_dir,
        non_verbose=True,
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


def main():
    args = parse_args()
    model_tag = args.model
    input_size = args.input_size

    # 1. 下载权重
    weights_path = download_weights(model_tag)

    # 2. 加载图像编码器
    vision_model = load_vision_encoder(model_tag, weights_path, input_size)

    # 3. 导出 ONNX
    onnx_path = export_onnx(vision_model, input_size, model_tag)

    # 4. 转换 TFLite
    tflite_path = export_tflite(onnx_path, model_tag)

    # 完成提示
    dest = f'frontend\\assets\\models\\mobileclip_{model_tag.lower()}_vision.tflite'
    print()
    print('=' * 60)
    print('✅ 完成！请执行以下命令：')
    print(f'  copy "{tflite_path}" {dest}')
    print()
    print('然后告诉 AI 助手「MobileCLIP 文件已就绪」')
    print('=' * 60)


if __name__ == '__main__':
    main()
