"""
fix_places365_labels.py
单独生成 places365_labels_zh.txt（365 行）。
TFLite 文件已经生成，只需补全标签文件。

运行方式（在项目根目录）：
  py -3.11 scripts\fix_places365_labels.py
  # 或 python scripts\fix_places365_labels.py（任意版本均可）
"""

import os
import urllib.request

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LABELS_OUT = os.path.join(SCRIPT_DIR, 'places365_labels_zh.txt')

# 从 MIT 下载官方 365 类别英文列表（每行格式：/x/classroom 1）
CATEGORIES_URL = "http://places2.csail.mit.edu/models_places365/categories_places365.txt"
CATEGORIES_PATH = os.path.join(SCRIPT_DIR, 'categories_places365.txt')

if not os.path.exists(CATEGORIES_PATH):
    print("正在下载官方类别列表...")
    urllib.request.urlretrieve(CATEGORIES_URL, CATEGORIES_PATH)
    print("完成")

# 解析英文类别（取最后一个/之后、空格之前的部分）
with open(CATEGORIES_PATH, 'r') as f:
    lines = f.readlines()

en_labels = []
for line in lines:
    # 格式例：/a/airfield 0
    parts = line.strip().split()
    if not parts:
        continue
    category = parts[0].split('/')[-1].replace('_', ' ')  # airfield → airfield
    en_labels.append(category)

assert len(en_labels) == 365, f"官方类别数量错误：{len(en_labels)}"
print(f"官方 365 类别已加载")

# 中文翻译字典（key = 英文类别名，全小写）
ZH_MAP = {
    "airport terminal": "机场候机厅",
    "alcove": "壁龛",
    "alley": "小巷",
    "amphitheater": "圆形剧场",
    "amusement arcade": "游乐场",
    "amusement park": "游乐园",
    "apartment building outdoor": "公寓楼外",
    "aquarium": "水族馆",
    "aqueduct": "水渠",
    "arch": "拱门",
    "archive": "档案馆",
    "arrival gate": "到达闸口",
    "art gallery": "美术馆",
    "art school": "艺术学校",
    "art studio": "艺术工作室",
    "arts and crafts": "手工艺",
    "assembly point": "集合点",
    "attic": "阁楼",
    "auditorium": "礼堂",
    "auto factory": "汽车工厂",
    "badlands": "荒地",
    "balcony exterior": "阳台外",
    "balcony interior": "阳台内",
    "bamboo forest": "竹林",
    "banquet hall": "宴会厅",
    "bar": "酒吧",
    "barn": "谷仓",
    "basement": "地下室",
    "basketball court indoor": "室内篮球场",
    "bathroom": "浴室",
    "bayou": "沼泽地",
    "beach": "海滩",
    "beach house": "海滨别墅",
    "beauty salon": "美容院",
    "bedroom": "卧室",
    "beer hall": "啤酒厅",
    "biology laboratory": "生物实验室",
    "boardwalk": "木栈道",
    "boat deck": "船甲板",
    "boathouse": "船屋",
    "bookstore": "书店",
    "botanical garden": "植物园",
    "bowling alley": "保龄球馆",
    "boxing ring": "拳击场",
    "bridge": "桥梁",
    "building facade": "建筑外墙",
    "bullpen": "牛棚",
    "bus interior": "公交车内",
    "butchers shop": "肉铺",
    "butte": "孤山",
    "cafeteria": "自助餐厅",
    "campsite": "露营地",
    "campus": "校园",
    "canal natural": "自然运河",
    "canal urban": "城市运河",
    "candy store": "糖果店",
    "canyon": "峡谷",
    "car interior": "车厢内",
    "casino": "赌场",
    "castle": "城堡",
    "cathedral indoor": "大教堂内",
    "cathedral outdoor": "大教堂外",
    "cavern indoor": "洞穴内",
    "cemetery": "公墓",
    "chalet": "木屋",
    "chemistry lab": "化学实验室",
    "childs room": "儿童房",
    "church indoor": "教堂内",
    "church outdoor": "教堂外",
    "classroom": "教室",
    "clean room": "洁净室",
    "cliff": "悬崖",
    "cloister indoor": "廊柱内",
    "closet": "衣橱",
    "clothing store": "服装店",
    "coast": "海岸",
    "cockpit": "驾驶舱",
    "coffee shop": "咖啡店",
    "computer room": "机房",
    "conference center": "会议中心",
    "conference room": "会议室",
    "construction site": "建筑工地",
    "corn field": "玉米地",
    "corridor": "走廊",
    "cottage": "农舍",
    "courthouse": "法院",
    "courtyard": "庭院",
    "creek": "小溪",
    "crosswalk": "人行横道",
    "dam": "水坝",
    "delicatessen": "熟食店",
    "dentists office": "牙科诊所",
    "desert sand": "沙漠沙地",
    "desert vegetation": "沙漠植被",
    "diner indoor": "小餐馆内",
    "diner outdoor": "小餐馆外",
    "dining car": "餐车",
    "dining room": "餐室",
    "discotheque": "迪厅",
    "doorway outdoor": "室外门口",
    "dorm room": "宿舍",
    "downtown": "市中心",
    "driveway": "车道",
    "drugstore": "药店",
    "elevator door": "电梯门",
    "elevator interior": "电梯内",
    "embassy": "大使馆",
    "engine room": "发动机房",
    "entrance hall": "门厅",
    "escarpment": "峭壁",
    "excavation": "挖掘现场",
    "factory indoor": "室内工厂",
    "fairway": "球道",
    "farm": "农场",
    "fastfood restaurant": "快餐厅",
    "field cultivated": "耕地",
    "field wild": "野地",
    "fire escape": "消防梯",
    "fire station": "消防站",
    "fishing pier": "钓鱼码头",
    "fish market": "鱼市",
    "flea market": "跳蚤市场",
    "florist shop": "花店",
    "flying deck": "飞行甲板",
    "football field": "足球场",
    "forest broadleaf": "阔叶林",
    "forest needleleaf": "针叶林",
    "formal garden": "正式花园",
    "fountain": "喷泉",
    "galley": "船廊",
    "garage indoor": "室内车库",
    "garage outdoor": "室外车库",
    "gas station": "加油站",
    "gazebo exterior": "室外凉亭",
    "general store indoor": "室内杂货店",
    "general store outdoor": "室外杂货店",
    "glacier": "冰川",
    "golf course": "高尔夫球场",
    "greenhouse indoor": "室内温室",
    "greenhouse outdoor": "室外温室",
    "grotto": "岩洞",
    "gymnasium indoor": "室内体育馆",
    "hangar indoor": "室内机库",
    "hangar outdoor": "室外机库",
    "harbor": "港口",
    "hardware store": "五金店",
    "hayfield": "干草地",
    "heliport": "直升机停机坪",
    "highway": "公路",
    "home office": "家庭办公室",
    "hospital": "医院",
    "hospital room": "病房",
    "hotel outdoor": "酒店外",
    "hotel room": "酒店房间",
    "house": "住宅",
    "hunting lodge outdoor": "狩猎小屋外",
    "ice cream parlor": "冰淇淋店",
    "ice floe": "浮冰",
    "ice shelf": "冰架",
    "ice skating rink indoor": "室内溜冰场",
    "ice skating rink outdoor": "室外溜冰场",
    "iceberg": "冰山",
    "igloo": "冰屋",
    "industrial area": "工业区",
    "inn outdoor": "室外客栈",
    "islet": "小岛",
    "jacuzzi indoor": "室内浴缸",
    "jail cell": "监狱牢房",
    "japanese garden": "日式花园",
    "jewelry shop": "珠宝店",
    "junkyard": "废料场",
    "kasbah": "古集市",
    "kennel outdoor": "室外犬舍",
    "kindergarden classroom": "幼儿园教室",
    "kitchen": "厨房",
    "kitchenette": "小厨房",
    "laundromat": "洗衣店",
    "lawn": "草坪",
    "lecture room": "演讲厅",
    "legislative chamber": "议事厅",
    "library indoor": "室内图书馆",
    "library outdoor": "室外图书馆",
    "lighthouse": "灯塔",
    "living room": "客厅",
    "loading dock": "装卸站",
    "lock chamber": "船闸",
    "loft": "复式公寓",
    "locker room": "更衣室",
    "lobby": "大堂",
    "lookout deck": "观景台",
    "machine shop": "机械车间",
    "mansion": "大厦",
    "market indoor": "室内市场",
    "market outdoor": "室外市场",
    "marsh": "沼泽",
    "martial arts gym": "武术馆",
    "mausoleum": "陵墓",
    "medina": "古城区",
    "mesa": "台地",
    "monastery outdoor": "室外修道院",
    "mosque indoor": "清真寺内",
    "mosque outdoor": "清真寺外",
    "motel": "汽车旅馆",
    "mountain": "山",
    "mountain path": "山路",
    "mountain snowy": "雪山",
    "movie theater indoor": "室内电影院",
    "museum indoor": "室内博物馆",
    "museum outdoor": "室外博物馆",
    "music studio": "音乐工作室",
    "natural history museum": "自然历史博物馆",
    "nursing home": "养老院",
    "ocean": "大海",
    "office": "办公室",
    "office building": "办公楼",
    "oil refinery": "炼油厂",
    "operating room": "手术室",
    "orchard": "果园",
    "outhouse": "户外厕所",
    "pagoda": "宝塔",
    "palace": "宫殿",
    "pantry": "储藏室",
    "parking garage indoor": "室内停车场",
    "parking garage outdoor": "室外停车场",
    "parking lot": "停车场",
    "pasture": "牧场",
    "patio": "露台",
    "pavilion": "亭子",
    "pharmacy": "药店",
    "phone booth": "电话亭",
    "picnic area": "野餐区",
    "pier": "码头",
    "pizzeria": "披萨店",
    "playground": "操场",
    "playroom": "游戏室",
    "plaza": "广场",
    "pond": "池塘",
    "porch": "门廊",
    "prison cell": "牢房",
    "pub indoor": "室内酒吧",
    "pulpit": "讲台",
    "putting green": "推杆练习场",
    "racecourse": "赛马场",
    "raceway": "赛车场",
    "raft": "木筏",
    "railroad track": "铁轨",
    "rainforest": "雨林",
    "reception": "接待处",
    "recreation room": "休息室",
    "repair shop": "修理店",
    "residential neighborhood": "住宅区",
    "restaurant": "餐厅",
    "restaurant kitchen": "餐厅厨房",
    "restaurant patio": "餐厅露台",
    "rice paddy": "稻田",
    "river": "河流",
    "rock arch": "岩石拱",
    "roof garden": "屋顶花园",
    "rope bridge": "绳桥",
    "ruin": "废墟",
    "runway": "跑道",
    "sand trap": "沙坑",
    "ski resort": "滑雪度假村",
    "ski slope": "滑雪坡",
    "sky": "天空",
    "skyscraper": "摩天大楼",
    "slum": "贫民窟",
    "snowfield": "雪地",
    "soccer field": "足球场",
    "sports facility": "运动设施",
    "stable": "马厩",
    "stadium baseball": "棒球场",
    "stadium football": "美式橄榄球场",
    "stadium soccer": "足球场",
    "staircase": "楼梯",
    "street": "街道",
    "subway interior": "地铁车厢",
    "subway station platform": "地铁站台",
    "supermarket": "超市",
    "swamp": "沼泽地",
    "swimming pool indoor": "室内游泳池",
    "swimming pool outdoor": "室外游泳池",
    "synagogue indoor": "犹太会堂内",
    "synagogue outdoor": "犹太会堂外",
    "television room": "电视室",
    "television studio": "电视演播室",
    "temple asia": "亚洲寺庙",
    "topiary garden": "绿植园艺",
    "tower": "塔楼",
    "toyshop": "玩具店",
    "track outdoor": "室外跑道",
    "train railway": "铁路",
    "train station platform": "火车站台",
    "tree farm": "林场",
    "trench": "战壕",
    "underwater coral reef": "珊瑚礁",
    "underwater ocean deep": "深海",
    "utility room": "工具室",
    "valley": "山谷",
    "van interior": "面包车内",
    "vegetable garden": "蔬菜园",
    "veranda": "走廊",
    "viaduct": "高架桥",
    "volcano": "火山",
    "volleyball court": "排球场",
    "waiting room": "等候室",
    "water tower": "水塔",
    "waterfall": "瀑布",
    "watering hole": "饮水处",
    "wave": "海浪",
    "wet bar": "湿吧台",
    "wheat field": "麦田",
    "wind farm": "风电场",
    "windmill": "风车",
    "yard": "庭院",
    "youth hostel": "青年旅舍",
}

def to_key(s):
    """把类别名转换为查询 key：去掉特殊符号、小写"""
    return s.lower().replace('/', ' ').replace('_', ' ').strip()

labels_out = []
missing_zh = []
for en in en_labels:
    key = to_key(en)
    zh = ZH_MAP.get(key)
    if zh:
        labels_out.append(zh)
    else:
        labels_out.append(en)  # 未翻译的用英文
        missing_zh.append(en)

if missing_zh:
    print(f"  {len(missing_zh)} 个类别未找到中文翻译（使用英文）：")
    for x in missing_zh[:10]:
        print(f"    {x}")
    if len(missing_zh) > 10:
        print(f"    ... 共 {len(missing_zh)} 个")

with open(LABELS_OUT, 'w', encoding='utf-8') as f:
    f.write('\n'.join(labels_out) + '\n')

print(f"\n✅ 标签文件已写入 {LABELS_OUT}（{len(labels_out)} 行）")
print()
print("=" * 60)
print("现在将以下文件复制到 frontend/assets/models/：")
tflite_path = os.path.join(SCRIPT_DIR, 'places365_resnet18.tflite')
print(f"  copy \"{tflite_path}\" frontend\\assets\\models\\places365_resnet18.tflite")
print(f"  copy \"{LABELS_OUT}\" frontend\\assets\\models\\places365_labels_zh.txt")
print("然后告诉 AI 助手「Places365 文件已就绪」")
print("=" * 60)
