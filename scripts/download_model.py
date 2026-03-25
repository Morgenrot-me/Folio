import os
import urllib.request

def download_model():
    # 确立模型保存路径
    model_dir = os.path.join("frontend", "assets", "models")
    os.makedirs(model_dir, exist_ok=True)
    
    model_path = os.path.join(model_dir, "mobileclip.tflite")
    if os.path.exists(model_path):
        os.remove(model_path) # 确保持续更新

    # 响应瘦身需求，更换为 MobileCLIP S0 (体积缩减极为夸张，仅需几十MB，极适合移动端纯单机推理)
    url = "https://huggingface.co/anton96vice/mobileclip2_tflite/resolve/main/mobileclip_s0_datacompdr_last.tflite"
    print(f"🚀 开始通过直连拉取 MobileCLIP S0 极致瘦身版推理模型...")
    print(f"网络源: {url}")
    
    try:
        # 添加 User-Agent 防屏蔽
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response, open(model_path, 'wb') as out_file:
            data = response.read()
            out_file.write(data)
            
        size_mb = os.path.getsize(model_path) / (1024 * 1024)
        print(f"✅ 下载并配置成功！文件已存盘至: {model_path}")
        print(f"📊 模型体积: {size_mb:.2f} MB")
    except Exception as e:
        print(f"❌ 下载发生错误，报错信息: {e}")

if __name__ == "__main__":
    download_model()
