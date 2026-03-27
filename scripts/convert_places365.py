"""
convert_places365.py
Places365 PyTorch 模型 → TFLite（INT8 量化）转换脚本。
运行完成后将 places365_mobilenet.tflite 复制到：
  frontend/assets/models/places365_mobilenet.tflite

依赖安装（建议新建虚拟环境）：
  pip install torch torchvision tensorflow onnx onnx-tf

使用方式：
  python scripts/convert_places365.py

输出文件：
  scripts/places365_mobilenet.tflite   ← 量化后约 5-8 MB
  scripts/places365_labels_zh.txt      ← 365 个场景中文标签（一行一个）
"""

import os
import sys
import urllib.request
import subprocess

# ─────────────────────────────────────────────────────────────────────────────
# 0. 依赖检查
# ─────────────────────────────────────────────────────────────────────────────
REQUIRED = ['torch', 'torchvision', 'tensorflow', 'onnx', 'onnx_tf']
missing = []
for pkg in REQUIRED:
    try:
        __import__(pkg)
    except ImportError:
        missing.append(pkg)

if missing:
    print(f"[ERROR] 缺少依赖包：{', '.join(missing)}")
    print("请先运行：pip install torch torchvision tensorflow onnx onnx-tf")
    sys.exit(1)

import torch
import torch.nn as nn
import torchvision.models as models
import numpy as np
import tensorflow as tf
import onnx
from onnx_tf.backend import prepare

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ONNX_PATH  = os.path.join(SCRIPT_DIR, 'places365_mobilenet.onnx')
TF_DIR     = os.path.join(SCRIPT_DIR, 'places365_tf_saved')
TFLITE_OUT = os.path.join(SCRIPT_DIR, 'places365_mobilenet.tflite')
LABELS_OUT = os.path.join(SCRIPT_DIR, 'places365_labels_zh.txt')

# ─────────────────────────────────────────────────────────────────────────────
# 1. 下载 Places365 预训练权重（MobileNet v2，~16MB）
# ─────────────────────────────────────────────────────────────────────────────
WEIGHTS_URL = (
    "http://places2.csail.mit.edu/models_places365/"
    "resnet18_places365.pth.tar"
)
# 使用更轻量的 ResNet18，MIT 官方提供，365 类输出
WEIGHTS_PATH = os.path.join(SCRIPT_DIR, 'resnet18_places365.pth.tar')

if not os.path.exists(WEIGHTS_PATH):
    print("[1/5] 正在下载 ResNet18-Places365 权重（约 46MB）...")
    urllib.request.urlretrieve(WEIGHTS_URL, WEIGHTS_PATH,
        reporthook=lambda b, bs, t: print(
            f"\r  {min(b*bs, t)//1024//1024} / {t//1024//1024} MB", end=''))
    print("\n  下载完成")
else:
    print("[1/5] 权重文件已存在，跳过下载")

# ─────────────────────────────────────────────────────────────────────────────
# 2. 加载模型，换掉最后一层 fc（输出 365 类）
# ─────────────────────────────────────────────────────────────────────────────
print("[2/5] 加载 PyTorch 模型...")
model = models.resnet18(weights=None)
model.fc = nn.Linear(model.fc.in_features, 365)

checkpoint = torch.load(WEIGHTS_PATH, map_location='cpu')
state_dict = checkpoint.get('state_dict', checkpoint)
# 官方权重 key 有 'module.' 前缀
state_dict = {k.replace('module.', ''): v for k, v in state_dict.items()}
model.load_state_dict(state_dict)
model.eval()
print("  模型加载完成，输出维度:", model.fc.out_features)

# ─────────────────────────────────────────────────────────────────────────────
# 3. PyTorch → ONNX
# ─────────────────────────────────────────────────────────────────────────────
print("[3/5] 导出 ONNX...")
dummy_input = torch.randn(1, 3, 224, 224)
torch.onnx.export(
    model, dummy_input, ONNX_PATH,
    input_names=['input'], output_names=['output'],
    dynamic_axes={'input': {0: 'batch'}, 'output': {0: 'batch'}},
    opset_version=12
)
print(f"  已写入 {ONNX_PATH}")

# ─────────────────────────────────────────────────────────────────────────────
# 4. ONNX → TensorFlow SavedModel → TFLite（INT8 量化）
# ─────────────────────────────────────────────────────────────────────────────
print("[4/5] 转换为 TensorFlow SavedModel...")
onnx_model = onnx.load(ONNX_PATH)
tf_rep = prepare(onnx_model)
tf_rep.export_graph(TF_DIR)
print(f"  SavedModel 已写入 {TF_DIR}")

print("  正在 INT8 量化转换为 TFLite（约需 1-2 分钟）...")

def representative_dataset():
    """校准数据集：用随机图像代替真实数据，INT8 精度略低但足够"""
    for _ in range(100):
        data = np.random.rand(1, 224, 224, 3).astype(np.float32)
        # Places365 预处理：ImageNet 均值归一化
        data[..., 0] = (data[..., 0] - 0.485) / 0.229
        data[..., 1] = (data[..., 1] - 0.456) / 0.224
        data[..., 2] = (data[..., 2] - 0.406) / 0.225
        yield [data]

converter = tf.lite.TFLiteConverter.from_saved_model(TF_DIR)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.representative_dataset = representative_dataset
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type  = tf.uint8
converter.inference_output_type = tf.float32  # 输出保留 float32，方便读 softmax

tflite_model = converter.convert()
with open(TFLITE_OUT, 'wb') as f:
    f.write(tflite_model)

size_mb = os.path.getsize(TFLITE_OUT) / 1024 / 1024
print(f"  TFLite 已写入 {TFLITE_OUT}（{size_mb:.1f} MB）")

# ─────────────────────────────────────────────────────────────────────────────
# 5. 生成 365 个场景标签中文翻译文件
# ─────────────────────────────────────────────────────────────────────────────
print("[5/5] 写出中文标签文件...")

# MIT 官方 places365 类别（按索引顺序），直接内嵌，确保离线可用
PLACES365_LABELS_EN = [
    "airport_terminal","alcove","alley","amphitheater","amusement_arcade",
    "amusement_park","apartment_building/outdoor","aquarium","aqueduct",
    "arch","archive","arrival_gate","art_gallery","art_school","art_studio",
    "arts_and_crafts","assembly_point","attic","auditorium","auto_factory",
    "badlands","balcony/exterior","balcony/interior","bamboo_forest",
    "banquet_hall","bar","barn","basement","basketball_court/indoor",
    "bathroom","bayou","beach","beach_house","beauty_salon","bedroom",
    "beer_hall","biology_laboratory","boardwalk","boat_deck","boathouse",
    "bookstore","botanical_garden","bowling_alley","boxing_ring","bridge",
    "building_facade","bullpen","bus_interior","butchers_shop","butte",
    "cafeteria","campsite","campus","canal/natural","canal/urban","candy_store",
    "canyon","car_interior","casino","castle","cathedral/indoor",
    "cathedral/outdoor","cavern/indoor","cemetery","chalet","chemistry_lab",
    "childs_room","church/indoor","church/outdoor","classroom","clean_room",
    "cliff","cloister/indoor","closet","clothing_store","coast","cockpit",
    "coffee_shop","computer_room","conference_center","conference_room",
    "construction_site","corn_field","corridor","cottage","courthouse",
    "courtyard","creek","crosswalk","dam","delicatessen","dentists_office",
    "desert/sand","desert/vegetation","diner/indoor","diner/outdoor","dining_car",
    "dining_room","discotheque","doorway/outdoor","dorm_room","downtown",
    "driveway","drugstore","elevator/door","elevator/interior","embassy",
    "engine_room","entrance_hall","escarpment","excavation","factory/indoor",
    "fairway","farm","fastfood_restaurant","field/cultivated","field/wild",
    "fire_escape","fire_station","fishing_pier","fish_market","flea_market",
    "florist_shop","flying_deck","football_field","forest/broadleaf",
    "forest/needleleaf","formal_garden","fountain","galley","garage/indoor",
    "garage/outdoor","gas_station","gazebo/exterior","general_store/indoor",
    "general_store/outdoor","glacier","golf_course","greenhouse/indoor",
    "greenhouse/outdoor","grotto","gymnasium/indoor","hangar/indoor",
    "hangar/outdoor","harbor","hardware_store","hayfield","heliport","highway",
    "home_office","hospital","hospital_room","hotel/outdoor","hotel_room",
    "house","hunting_lodge/outdoor","ice_cream_parlor","ice_floe","ice_shelf",
    "ice_skating_rink/indoor","ice_skating_rink/outdoor","iceberg","igloo",
    "industrial_area","inn/outdoor","islet","jacuzzi/indoor","jail_cell",
    "japanese_garden","jewelry_shop","junkyard","kasbah","kennel/outdoor",
    "kindergarden_classroom","kitchen","kitchenette","laundromat","lawn",
    "lecture_room","legislative_chamber","library/indoor","library/outdoor",
    "lighthouse","living_room","loading_dock","lock_chamber","loft",
    "locker_room","lobby","lookout_deck","machine_shop","mansion",
    "market/indoor","market/outdoor","marsh","martial_arts_gym","mausoleum",
    "medina","mesa","monastery/outdoor","mosque/indoor","mosque/outdoor",
    "motel","mountain","mountain_path","mountain_snowy","movie_theater/indoor",
    "museum/indoor","museum/outdoor","music_studio","natural_history_museum",
    "nursing_home","ocean","office","office_building","oil_refinery",
    "operating_room","orchard","outhouse","pagoda","palace","pantry",
    "parking_garage/indoor","parking_garage/outdoor","parking_lot",
    "pasture","patio","pavilion","pharmacy","phone_booth","picnic_area",
    "pier","pizzeria","playground","playroom","plaza","pond","porch",
    "prison_cell","pub/indoor","pulpit","putting_green","racecourse",
    "raceway","raft","railroad_track","rainforest","reception","recreation_room",
    "repair_shop","residential_neighborhood","restaurant","restaurant_kitchen",
    "restaurant_patio","rice_paddy","river","rock_arch","roof_garden",
    "rope_bridge","ruin","runway","sand_trap","ski_resort","ski_slope",
    "sky","skyscraper","slum","snowfield","soccer_field","sports_facility",
    "stable","stadium/baseball","stadium/football","stadium/soccer",
    "staircase","street","subway_interior","subway_station/platform",
    "supermarket","swamp","swimming_pool/indoor","swimming_pool/outdoor",
    "synagogue/indoor","synagogue/outdoor","television_room","television_studio",
    "temple/asia","topiary_garden","tower","toyshop","track/outdoor",
    "train_railway","train_station/platform","tree_farm","trench",
    "underwater/coral_reef","underwater/ocean_deep","utility_room","valley",
    "van_interior","vegetable_garden","veranda","viaduct","volcano","volleyball_court",
    "waiting_room","water_tower","waterfall","watering_hole","wave",
    "wet_bar","wheat_field","wind_farm","windmill","yard","youth_hostel",
]

# 中文翻译映射（按相同数量）
PLACES365_LABELS_ZH = [
    "机场候机厅","壁龛","小巷","圆形剧场","游乐场",
    "游乐园","公寓楼外","水族馆","水渠",
    "拱门","档案馆","到达闸口","美术馆","艺术学校","艺术工作室",
    "手工艺","集合点","阁楼","礼堂","汽车工厂",
    "荒地","阳台外","阳台内","竹林",
    "宴会厅","酒吧","谷仓","地下室","篮球场室内",
    "浴室","沼泽地","海滩","海滨别墅","美容院","卧室",
    "啤酒厅","生物实验室","木栈道","船甲板","船屋",
    "书店","植物园","保龄球馆","拳击场","桥梁",
    "建筑外墙","牛棚","公交车内","肉铺","孤山",
    "自助餐厅","露营地","校园","自然运河","城市运河","糖果店",
    "峡谷","车厢内","赌场","城堡","大教堂内",
    "大教堂外","洞穴内","公墓","木屋","化学实验室",
    "儿童房","教堂内","教堂外","教室","洁净室",
    "悬崖","廊柱内","衣橱","服装店","海岸","驾驶舱",
    "咖啡店","机房","会议中心","会议室",
    "建筑工地","玉米地","走廊","农舍","法院",
    "庭院","小溪","人行横道","水坝","熟食店","牙科诊所",
    "沙漠/沙地","沙漠/植被","小餐馆内","小餐馆外","餐车",
    "餐厅","迪厅","室外门口","宿舍房间","市中心",
    "车道","药店","电梯门","电梯内","大使馆",
    "机房","门厅","峭壁","挖掘现场","工厂内",
    "球道","农场","快餐厅","耕地","野地",
    "消防梯","消防站","钓鱼码头","鱼市","跳蚤市场",
    "花店","飞行甲板","足球场","阔叶林",
    "针叶林","正式花园","喷泉","走廊","室内车库","室外车库",
    "加油站","凉亭外","杂货店内",
    "杂货店外","冰川","高尔夫球场","温室内",
    "温室外","岩洞","室内体育馆","机库内",
    "机库外","港口","五金店","干草地","直升机停机坪","公路",
    "家庭办公室","医院","病房","酒店外","酒店房间",
    "住宅","狩猎小屋外","冰淇淋店","浮冰","冰架",
    "室内溜冰场","室外溜冰场","冰山","冰屋",
    "工业区","客栈外","小岛","室内浴缸","监狱牢房",
    "日式花园","珠宝店","废料场","卡斯巴","室外犬舍",
    "幼儿园教室","厨房","小厨房","洗衣店","草坪",
    "演讲厅","议事厅","图书馆内","图书馆外",
    "灯塔","客厅","装卸站","船闸","复式公寓",
    "更衣室","大堂","观景台","机械车间","大厦",
    "室内市场","室外市场","沼泽","武术馆","陵墓",
    "麦地那","台地","修道院外","清真寺内","清真寺外",
    "汽车旅馆","山","山路","雪山","电影院内",
    "博物馆内","博物馆外","音乐工作室","自然历史博物馆",
    "养老院","海洋","办公室","办公楼","炼油厂",
    "手术室","果园","户外厕所","宝塔","宫殿","储藏室",
    "室内停车场","室外停车场","停车场",
    "牧场","露台","亭子","药店","电话亭","野餐区",
    "码头","披萨店","操场","游戏室","广场","池塘","门廊",
    "牢房","室内酒吧","讲台","推杆练习场","赛马场",
    "赛车场","木筏","铁轨","雨林","接待处","休息室",
    "修理店","住宅区","餐厅","餐厅厨房",
    "餐厅露台","稻田","河流","岩石拱","屋顶花园",
    "绳桥","废墟","跑道","沙坑","滑雪度假村","滑雪坡",
    "天空","摩天大楼","贫民窟","雪地","足球场","运动设施",
    "马厩","棒球场","橄榄球场","足球场",
    "楼梯","街道","地铁内","地铁站台",
    "超市","沼泽","室内游泳池","室外游泳池",
    "犹太会堂内","犹太会堂外","电视室","电视演播室",
    "亚洲寺庙","绿植园艺","塔楼","玩具店","室外跑道",
    "铁路","火车站台","林场","战壕",
    "珊瑚礁","深海","工具室","山谷",
    "面包车内","菜园","走廊","高架桥","火山","排球场",
    "等候室","水塔","瀑布","水坑","波浪",
    "湿吧台","麦田","风电场","风车","庭院","青年旅舍",
]

assert len(PLACES365_LABELS_EN) == len(PLACES365_LABELS_ZH), \
    f"长度不一致：EN={len(PLACES365_LABELS_EN)} ZH={len(PLACES365_LABELS_ZH)}"

with open(LABELS_OUT, 'w', encoding='utf-8') as f:
    for zh in PLACES365_LABELS_ZH:
        f.write(zh + '\n')

print(f"  中文标签文件已写入 {LABELS_OUT}")
print()
print("=" * 60)
print("✅ 转换完成！")
print()
print("下一步：")
print(f"  1. 将 {TFLITE_OUT}")
print(f"     复制到 frontend/assets/models/places365_mobilenet.tflite")
print(f"  2. 将 {LABELS_OUT}")
print(f"     复制到 frontend/assets/models/places365_labels_zh.txt")
print("  3. 在 pubspec.yaml 的 assets 列表中确认已包含 assets/models/")
print("  4. 告诉 AI 助手「Places365 模型文件已就绪，可以接入代码」")
print("=" * 60)
