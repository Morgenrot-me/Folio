import urllib.request
import os

# Github 开源的 1000 类 ImageNet 标准中文对照表
url = "https://raw.githubusercontent.com/DWHNicholas/ImageNet_chinese_cls/master/label_cn.txt"
print("Fetching Open-Source Chinese ImageNet labels...")
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    content = urllib.request.urlopen(req).read().decode('utf-8').splitlines()
    out_dir = os.path.join("frontend", "lib", "core", "constants")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "imagenet_labels.dart")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("class ImageNetLabels {\n  static const List<String> labels = [\n")
        # 逐行清洗换行和未知字符，组装进 Dart 静态数组
        for line in content:
            clean_word = line.strip()
            if clean_word:
                f.write(f'    "{clean_word}",\n')
        f.write("  ];\n}\n")
    print(f"✅ Successfully localized {len(content)} Chinese object labels and wrote to {out_path}")
except Exception as e:
    print(f"❌ Error fetching Chinese labels: {e}")
