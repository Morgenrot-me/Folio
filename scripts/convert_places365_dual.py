"""
convert_places365_dual.py
将 Places365 ResNet18 重新导出为「双输出」TFLite：
  输出 0：512 维 avgpool 语义向量  ← 用于聚类 / 相似搜索
  输出 1：365 维 logits           ← 用于场景标签（与之前相同）

好处：复用已有模型（+0 APK 体积），一次推理得到两个结果。

运行方式：
  py -3.11 scripts\convert_places365_dual.py

完成后将输出文件覆盖 frontend/assets/models/places365_resnet18.tflite
"""

import os
import sys
import urllib.request

import torch
import torch.nn as nn
import torchvision.models as models
import numpy as np
import onnx
import onnx.helper

# ── monkey-patch onnx.helper.float32_to_bfloat16（onnx_graphsurgeon 需要）─
if not hasattr(onnx.helper, 'float32_to_bfloat16'):
    def _f32_to_bf16(val):
        arr = np.asarray(val, dtype=np.float32)
        return (arr.view(np.uint32) >> 16).astype(np.uint16)
    onnx.helper.float32_to_bfloat16 = _f32_to_bf16

import onnx2tf

SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
ONNX_PATH    = os.path.join(SCRIPT_DIR, 'places365_dual.onnx')
TF_DIR       = os.path.join(SCRIPT_DIR, 'places365_dual_tf')
TFLITE_OUT   = os.path.join(SCRIPT_DIR, 'places365_resnet18.tflite')
WEIGHTS_PATH = os.path.join(SCRIPT_DIR, 'resnet18_places365.pth.tar')

# ─────────────────────────────────────────────────────────────────────────────
# 1. 下载权重（若已存在则跳过）
# ─────────────────────────────────────────────────────────────────────────────
WEIGHTS_URL = ("http://places2.csail.mit.edu/models_places365/"
               "resnet18_places365.pth.tar")
if not os.path.exists(WEIGHTS_PATH):
    print("[1/4] 下载权重（约 46 MB）...")
    def _prog(b, bs, t):
        print(f"\r  {min(b*bs,t)//1024//1024}/{t//1024//1024} MB", end='', flush=True)
    urllib.request.urlretrieve(WEIGHTS_URL, WEIGHTS_PATH, reporthook=_prog)
    print()
else:
    print("[1/4] 权重已存在，跳过")

# ─────────────────────────────────────────────────────────────────────────────
# 2. 构建双输出 Wrapper Model
# ─────────────────────────────────────────────────────────────────────────────
print("[2/4] 构建双输出 ResNet18...")

class Resnet18DualOutput(nn.Module):
    """
    ResNet18 Places365 包装器，同时输出：
      - feature: 512 维 avgpool 向量（L2 归一化，更适合余弦相似度）
      - logits:  365 维分类输出
    """
    def __init__(self, base: nn.Module):
        super().__init__()
        # 复用 ResNet18 的各层
        self.conv1    = base.conv1
        self.bn1      = base.bn1
        self.relu     = base.relu
        self.maxpool  = base.maxpool
        self.layer1   = base.layer1
        self.layer2   = base.layer2
        self.layer3   = base.layer3
        self.layer4   = base.layer4
        self.avgpool  = base.avgpool
        self.fc       = base.fc

    def forward(self, x):
        x = self.conv1(x)
        x = self.bn1(x)
        x = self.relu(x)
        x = self.maxpool(x)
        x = self.layer1(x)
        x = self.layer2(x)
        x = self.layer3(x)
        x = self.layer4(x)
        x = self.avgpool(x)
        feat = torch.flatten(x, 1)            # [1, 512]
        # L2 归一化，使余弦相似度 = 点积，方便 Flutter 端计算
        feat_norm = feat / (feat.norm(dim=1, keepdim=True) + 1e-8)
        logits = self.fc(feat)                 # [1, 365]
        return feat_norm, logits

base = models.resnet18(weights=None)
base.fc = nn.Linear(base.fc.in_features, 365)
checkpoint = torch.load(WEIGHTS_PATH, map_location='cpu', weights_only=False)
state_dict = checkpoint.get('state_dict', checkpoint)
state_dict = {k.replace('module.', ''): v for k, v in state_dict.items()}
base.load_state_dict(state_dict)
base.eval()

model = Resnet18DualOutput(base)
model.eval()
print("  完成，输出：feat[1,512] + logits[1,365]")

# ─────────────────────────────────────────────────────────────────────────────
# 3. 导出 ONNX（双输出）
# ─────────────────────────────────────────────────────────────────────────────
print("[3/4] 导出 ONNX...")
dummy = torch.randn(1, 3, 224, 224)
torch.onnx.export(
    model, dummy, ONNX_PATH,
    input_names=['input'],
    output_names=['feature', 'logits'],
    opset_version=18,   # 用 18（与 torch 自动选择一致，避免降级警告）
)
print(f"  {ONNX_PATH} ({os.path.getsize(ONNX_PATH)//1024//1024} MB)")

# ─────────────────────────────────────────────────────────────────────────────
# 4. ONNX → TFLite（via onnx2tf）
# ─────────────────────────────────────────────────────────────────────────────
print("[4/4] onnx2tf 转换（约 60 秒）...")
os.makedirs(TF_DIR, exist_ok=True)
onnx2tf.convert(
    input_onnx_file_path=ONNX_PATH,
    output_folder_path=TF_DIR,
    non_verbose=True,
)

# 找到生成的 tflite 文件
src = None
for f in os.listdir(TF_DIR):
    if f.endswith('.tflite'):
        src = os.path.join(TF_DIR, f)
        break
if not src:
    print("[ERROR] 未找到输出 .tflite，请检查:", TF_DIR)
    sys.exit(1)

import shutil
shutil.copy2(src, TFLITE_OUT)
size_mb = os.path.getsize(TFLITE_OUT) / 1024 / 1024
print(f"  已写入 {TFLITE_OUT}（{size_mb:.1f} MB）")

print()
print("=" * 60)
print("✅ 完成！将此文件覆盖到 frontend/assets/models/：")
print(f"  copy \"{TFLITE_OUT}\" "
      "\"frontend\\assets\\models\\places365_resnet18.tflite\"")
print("告诉 AI 助手「双输出 TFLite 已就绪」")
print("=" * 60)
