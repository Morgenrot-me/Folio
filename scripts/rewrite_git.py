import subprocess
import os

filter_script = os.path.abspath('msg_filter.py').replace('\\\\', '/')
with open(filter_script, 'w', encoding='utf-8') as f:
    f.write('''
import sys
import os

try:
    msg = sys.stdin.read().strip()
except UnicodeDecodeError:
    msg = sys.stdin.buffer.read().decode('utf-8', 'ignore').strip()

translations = {
    'Init: Set up Flutter frontend and basic project structure': '初始化：搭建 Flutter 前端架构与基础项目目录结构',
    'feat: setup drift database and 5 core tables': '特性：引入 Drift 本地数据库并创建 5 张核心数据表',
    'feat: add photo_manager, configure android permissions and create initial media scanner service': '特性：引入 photo_manager，配置安卓权限并构建初始相册扫描服务',
    'feat: scaffold feature_extractor_service with ML Kit text recognition and structure': '特性：搭建基于 ML Kit 的特征提取服务骨架与文字识别逻辑',
    'feat: implement modern M3 app shell, AppTheme, root navigation and home view': '特性：实现 Material 3 现代主页界面、深色极简主题及底层模块导航'
}

for k, v in translations.items():
    if k in msg or msg.startswith(k[:20]):
        print(v)
        sys.exit(0)

print(msg)
''')

cmd = f'git filter-branch -f --msg-filter "python \\"{filter_script}\\"" HEAD'
print("Running git filter-branch...")
result = subprocess.run(cmd, cwd=os.getcwd(), shell=True, capture_output=True, text=True)
print(result.stdout)
print(result.stderr)

if os.path.exists(filter_script):
    os.remove(filter_script)
