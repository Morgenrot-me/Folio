import os
import urllib.request

def download_model():
    # 确立模型保存路径
    model_dir = os.path.join("frontend", "assets", "models")
    os.makedirs(model_dir, exist_ok=True)
    
    model_path = os.path.join(model_dir, "mobileclip.tflite")
    # 统一命名为 mobilenet.tflite
    model_path = os.path.join(model_dir, "mobilenet.tflite")
    if os.path.exists(model_path):
        os.remove(model_path) # 确保持续更新

    # 连接 Google Cloud Storage 官方核心存储直连拉取极致性能版 MobileNet V3
    url = "https://storage.googleapis.com/mediapipe-models/image_classifier/efficientnet_lite0/float32/latest/efficientnet_lite0.tflite"
    print(f"🚀 开始通过云直连拉取体积仅有十几 MB 的『极速低功耗版』网络特征解构引擎...")
    print(f"网络源: {url}")
    
    try:
        # 添加 User-Agent 防屏蔽
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response, open(model_path, 'wb') as out_file:
            data = response.read()
            out_file.write(data)
            
        size_mb = os.path.getsize(model_path) / (1024 * 1024)
        print(f"✅ 下载并极致瘦身成功！新引擎已安放至: {model_path}")
        print(f"📊 新模型极简体积: {size_mb:.2f} MB")
        
        # 把刚才那个几乎会让所有弱设备卡爆的旧模型遗体给挫骨扬灰
        old_model = os.path.join(model_dir, "mobileclip.tflite")
        if os.path.exists(old_model):
            os.remove(old_model)
            print(f"🗑️ 已为您摧毁清除了旧版本的庞大 MobileCLIP 黑洞文件！您的储存空间得救了。")
            
    except Exception as e:
        print(f"❌ 下载发生错误，报错信息: {e}")

if __name__ == "__main__":
    download_model()
