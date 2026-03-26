import urllib.request
import os

url = "https://raw.githubusercontent.com/pytorch/hub/master/imagenet_classes.txt"
print("Fetching PyTorch Original ImageNet labels...")
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    content = urllib.request.urlopen(req).read().decode('utf-8').splitlines()
    out_dir = os.path.join("frontend", "lib", "core", "constants")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "imagenet_labels.dart")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("class ImageNetLabels {\n  static const List<String> labels = [\n")
        for line in content:
            f.write(f'    "{line.strip()}",\n')
        f.write("  ];\n}\n")
    print(f"Successfully wrote {len(content)} standard English noun labels to {out_path}")
except Exception as e:
    print(f"Error: {e}")
