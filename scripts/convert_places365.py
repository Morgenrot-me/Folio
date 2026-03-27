"""
convert_places365.py
Places365 PyTorch 模型 → ONNX → TFLite 转换脚本。
使用 onnx2tf（对 Python 3.13 兼容性最好）替代 onnx-tf / ai_edge_torch。

依赖安装：
  pip install torch torchvision onnx onnx2tf sng4onnx

使用方式：
  python scripts\convert_places365.py

完成后将以下文件复制到 frontend/assets/models/：
  scripts/places365_resnet18.tflite
  scripts/places365_labels_zh.txt
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

# ── monkey-patch：onnx_graphsurgeon 依赖此函数，但新版 onnx 已移除 ──────────
if not hasattr(onnx.helper, 'float32_to_bfloat16'):
    def _float32_to_bfloat16(val):
        arr = np.asarray(val, dtype=np.float32)
        return (arr.view(np.uint32) >> 16).astype(np.uint16)
    onnx.helper.float32_to_bfloat16 = _float32_to_bfloat16

import onnx2tf

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ONNX_PATH  = os.path.join(SCRIPT_DIR, 'places365_resnet18.onnx')
TF_DIR     = os.path.join(SCRIPT_DIR, 'places365_tf_out')
TFLITE_OUT = os.path.join(SCRIPT_DIR, 'places365_resnet18.tflite')
LABELS_OUT = os.path.join(SCRIPT_DIR, 'places365_labels_zh.txt')

# ─────────────────────────────────────────────────────────────────────────────
# 1. 下载 MIT 官方 ResNet18-Places365 权重（46 MB）
# ─────────────────────────────────────────────────────────────────────────────
WEIGHTS_URL  = ("http://places2.csail.mit.edu/models_places365/"
                "resnet18_places365.pth.tar")
WEIGHTS_PATH = os.path.join(SCRIPT_DIR, 'resnet18_places365.pth.tar')

if not os.path.exists(WEIGHTS_PATH):
    print("[1/4] 正在下载权重（约 46 MB）...")
    def _prog(b, bs, t):
        print(f"\r  {min(b*bs,t)//1024//1024} / {t//1024//1024} MB",
              end='', flush=True)
    urllib.request.urlretrieve(WEIGHTS_URL, WEIGHTS_PATH, reporthook=_prog)
    print("\n  完成")
else:
    print("[1/4] 权重文件已存在，跳过下载")

# ─────────────────────────────────────────────────────────────────────────────
# 2. 加载 PyTorch 模型
# ─────────────────────────────────────────────────────────────────────────────
print("[2/4] 加载 PyTorch ResNet18-Places365...")
model = models.resnet18(weights=None)
model.fc = nn.Linear(model.fc.in_features, 365)
checkpoint = torch.load(WEIGHTS_PATH, map_location='cpu', weights_only=False)
state_dict = checkpoint.get('state_dict', checkpoint)
state_dict = {k.replace('module.', ''): v for k, v in state_dict.items()}
model.load_state_dict(state_dict)
model.eval()
print(f"  输出维度 = {model.fc.out_features}")

# ─────────────────────────────────────────────────────────────────────────────
# 3. PyTorch → ONNX（opset 12，兼容性最好）
# ─────────────────────────────────────────────────────────────────────────────
print("[3/4] 导出 ONNX...")
dummy = torch.randn(1, 3, 224, 224)
torch.onnx.export(
    model, dummy, ONNX_PATH,
    input_names=['input'], output_names=['output'],
    opset_version=12,
)
print(f"  写入 {ONNX_PATH}（{os.path.getsize(ONNX_PATH)//1024//1024} MB）")

# ─────────────────────────────────────────────────────────────────────────────
# 4. ONNX → TFLite（via onnx2tf）
# ─────────────────────────────────────────────────────────────────────────────
print("[4/4] onnx2tf 转换为 TFLite（约 30-90 秒）...")
os.makedirs(TF_DIR, exist_ok=True)

onnx2tf.convert(
    input_onnx_file_path=ONNX_PATH,
    output_folder_path=TF_DIR,
    non_verbose=True,
)

# onnx2tf 默认输出文件名：<model_name>_float32.tflite
possible = [
    os.path.join(TF_DIR, 'places365_resnet18_float32.tflite'),
    os.path.join(TF_DIR, 'model_float32.tflite'),
]
src_tflite = None
for p in possible:
    if os.path.exists(p):
        src_tflite = p
        break

if src_tflite is None:
    # 搜索 TF_DIR 下所有 .tflite
    for f in os.listdir(TF_DIR):
        if f.endswith('.tflite'):
            src_tflite = os.path.join(TF_DIR, f)
            break

if src_tflite is None:
    print("[ERROR] 未找到输出 .tflite 文件，请检查 onnx2tf 输出目录：", TF_DIR)
    sys.exit(1)

import shutil
shutil.copy2(src_tflite, TFLITE_OUT)
size_mb = os.path.getsize(TFLITE_OUT) / 1024 / 1024
print(f"  TFLite 写入 {TFLITE_OUT}（{size_mb:.1f} MB）")

# ─────────────────────────────────────────────────────────────────────────────
# 5. 生成中文标签文件（365 行）
# ─────────────────────────────────────────────────────────────────────────────
LABELS_ZH = [
    "机场候机厅","壁龛","小巷","圆形剧场","游乐场",
    "游乐园","公寓楼外","水族馆","水渠","拱门",
    "档案馆","到达闸口","美术馆","艺术学校","艺术工作室",
    "手工艺","集合点","阁楼","礼堂","汽车工厂",
    "荒地","阳台外","阳台内","竹林","宴会厅",
    "酒吧","谷仓","地下室","室内篮球场","浴室",
    "沼泽地","海滩","海滨别墅","美容院","卧室",
    "啤酒厅","生物实验室","木栈道","船甲板","船屋",
    "书店","植物园","保龄球馆","拳击场","桥梁",
    "建筑外墙","牛棚","公交车内","肉铺","孤山",
    "自助餐厅","露营地","校园","自然运河","城市运河",
    "糖果店","峡谷","车厢内","赌场","城堡",
    "大教堂内","大教堂外","洞穴内","公墓","木屋",
    "化学实验室","儿童房","教堂内","教堂外","教室",
    "洁净室","悬崖","廊柱内","衣橱","服装店",
    "海岸","驾驶舱","咖啡店","机房","会议中心",
    "会议室","建筑工地","玉米地","走廊","农舍",
    "法院","庭院","小溪","人行横道","水坝",
    "熟食店","牙科诊所","沙漠沙地","沙漠植被","小餐馆内",
    "小餐馆外","餐车","餐室","迪厅","室外门口",
    "宿舍","市中心","车道","药店","电梯门",
    "电梯内","大使馆","发动机房","门厅","峭壁",
    "挖掘现场","室内工厂","球道","农场","快餐厅",
    "耕地","野地","消防梯","消防站","钓鱼码头",
    "鱼市","跳蚤市场","花店","飞行甲板","足球场",
    "阔叶林","针叶林","正式花园","喷泉","船廊",
    "室内车库","室外车库","加油站","室外凉亭","室内杂货店",
    "室外杂货店","冰川","高尔夫球场","室内温室","室外温室",
    "岩洞","室内体育馆","室内机库","室外机库","港口",
    "五金店","干草地","直升机停机坪","公路","家庭办公室",
    "医院","病房","酒店外","酒店房间","住宅",
    "狩猎小屋外","冰淇淋店","浮冰","冰架","室内溜冰场",
    "室外溜冰场","冰山","冰屋","工业区","室外客栈",
    "小岛","室内浴缸","监狱牢房","日式花园","珠宝店",
    "废料场","古集市","室外犬舍","幼儿园教室","厨房",
    "小厨房","洗衣店","草坪","演讲厅","议事厅",
    "室内图书馆","室外图书馆","灯塔","客厅","装卸站",
    "船闸","复式公寓","更衣室","大堂","观景台",
    "机械车间","大厦","室内市场","室外市场","沼泽",
    "武术馆","陵墓","古城区","台地","室外修道院",
    "清真寺内","清真寺外","汽车旅馆","山","山路",
    "雪山","室内电影院","室内博物馆","室外博物馆","音乐工作室",
    "自然历史博物馆","养老院","大海","办公室","办公楼",
    "炼油厂","手术室","果园","户外厕所","宝塔",
    "宫殿","储藏室","室内停车场","室外停车场","停车场",
    "牧场","露台","亭子","药店","电话亭",
    "野餐区","码头","披萨店","操场","游戏室",
    "广场","池塘","门廊","牢房","室内酒吧",
    "讲台","推杆练习场","赛马场","赛车场","木筏",
    "铁轨","雨林","接待处","休息室","修理店",
    "住宅区","餐厅","餐厅厨房","餐厅露台","稻田",
    "河流","岩石拱","屋顶花园","绳桥","废墟",
    "跑道","沙坑","滑雪度假村","滑雪坡","天空",
    "摩天大楼","贫民窟","雪地","足球场","运动设施",
    "马厩","棒球场","橄榄球场","足球场","楼梯",
    "街道","地铁车厢","地铁站台","超市","沼泽地",
    "室内游泳池","室外游泳池","犹太会堂内","犹太会堂外","电视室",
    "电视演播室","亚洲寺庙","绿植园艺","塔楼","玩具店",
    "室外跑道","铁路","火车站台","林场","战壕",
    "珊瑚礁","深海","工具室","山谷","面包车内",
    "蔬菜园","走廊","高架桥","火山","排球场",
    "等候室","水塔","瀑布","饮水处","海浪",
    "湿吧台","麦田","风电场","风车","庭院","青年旅舍",
]

assert len(LABELS_ZH) == 365, f"标签数量错误：{len(LABELS_ZH)}"

with open(LABELS_OUT, 'w', encoding='utf-8') as f:
    f.write('\n'.join(LABELS_ZH) + '\n')
print(f"  中文标签 → {LABELS_OUT}")

print()
print("=" * 60)
print("✅ 完成！请执行：")
print(f"  copy \"{TFLITE_OUT}\" frontend\\assets\\models\\places365_resnet18.tflite")
print(f"  copy \"{LABELS_OUT}\" frontend\\assets\\models\\places365_labels_zh.txt")
print("然后告诉 AI 助手「Places365 文件已就绪」")
print("=" * 60)
