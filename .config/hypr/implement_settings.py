import json
import os

def apply_settings():
    with open('CONFIG.json', 'r') as f:
        config = json.load(f)

    with open('colors.rasi', 'w') as f:
        # 构建 colors.rasi 文件内容
        content = f"""
* {{
bg: {config["colors"]["bg"]};
bga: {config["colors"]["bga"]};
fg: {config["colors"]["fg"]};
ac: {config["colors"]["ac"]};
se: {config["colors"]["se"]};
}}
        """
        f.write(content)
    
    
