#!/usr/bin/env python3
import threading
import time
import json
import subprocess
from PIL import Image, ImageDraw
import pystray
from pathlib import Path

class PomodoroTimer:
    def __init__(self):
        with open(str(Path.home() / '.config/hypr/CONFIG.json'), 'r') as f:
            config = json.load(f)
        self.work_duration = config["pomodoro"]["work_duration"]  # 工作时间
        self.break_duration = config["pomodoro"]["break_duration"]      # 休息时间
        self.is_running = True        # 启动时自动开始
        self.is_break_time = False
        self.remaining_time = self.work_duration
        self.icon_path = str(Path.home() / '.config/hypr/pomodoro.png')
        
        self.setup_tray()

    def update_tray_icon(self):
        """更新系统托盘图标"""
        try:
            # 加载pomodoro.png文件作为图标
            image = Image.open(self.icon_path)
            
            # 在图标上添加剩余时间
            draw = ImageDraw.Draw(image)
            minutes = self.remaining_time // 60
            seconds = self.remaining_time % 60
            
            # 显示时间文本
            display_text = f"{seconds}" if minutes == 0 else f"{minutes}"
            font_size = 16 if minutes == 0 else 20
            draw.text((32, 32), display_text, fill='white', anchor="mm", font_size=font_size)
            
            # 更新托盘图标
            if hasattr(self, 'icon'):
                self.icon.icon = image
        except Exception as e:
            print(f"无法加载图标文件: {e}")
            # 创建临时图标
            image = Image.new('RGBA', (64, 64), (255, 255, 255, 0))
            draw = ImageDraw.Draw(image)
            draw.ellipse([8, 8, 56, 56], fill='red', outline='darkred', width=2)
            draw.text((32, 32), "🍅", fill='white', anchor="mm", font_size=24)
            if hasattr(self, 'icon'):
                self.icon.icon = image

    def send_notification(self, message):
        """发送桌面通知"""
        try:
            subprocess.run(['notify-send', 'Arona', message, '-t', '5000', f'--icon={self.icon_path}'])
        except Exception as e:
            print(f"通知发送失败: {e}")

    def timer_loop(self):
        """定时器主循环"""
        self.send_notification("你好sensei，开始你一天的工作吧！")
        
        while True:
            if self.is_running and self.remaining_time > 0:
                self.remaining_time -= 1
                # 每10秒更新一次图标
                if self.remaining_time % 1 == 0:
                    self.update_tray_icon()
                    # 同时更新菜单
                    self.update_menu()
                time.sleep(1)
            elif self.is_running and self.remaining_time <= 0:
                # 时间到
                if self.is_break_time:
                    # 休息结束，开始工作
                    self.is_break_time = False
                    self.remaining_time = self.work_duration
                    self.send_notification("叮叮，休息时间到了，继续你的工作吧！")
                else:
                    # 工作结束，开始休息
                    self.is_break_time = True
                    self.remaining_time = self.break_duration
                    self.send_notification(f"嘻嘻，你已经工作了{self.work_duration // 60}分钟了，休息{self.break_duration}秒吧！")
                
                self.update_tray_icon()
                # 同时更新菜单
                self.update_menu()
            else:
                time.sleep(1)

    def start_timer(self, icon=None, item=None):
        """启动定时器"""
        if not self.is_running:
            self.is_running = True
            self.send_notification("番茄钟已启动")
            self.update_menu()

    def stop_timer(self, icon=None, item=None):
        """停止定时器"""
        if self.is_running:
            self.is_running = False
            self.send_notification("番茄钟已暂停")
            self.update_menu()

    def reset_timer(self, icon=None, item=None):
        """重置定时器"""
        self.is_running = True
        self.is_break_time = False
        self.remaining_time = self.work_duration
        self.update_menu()
        self.send_notification("番茄钟已重置并开始")

    def get_status_text(self):
        """获取状态文本"""
        status = "休息中" if self.is_break_time else "工作中"
        minutes = self.remaining_time // 60
        seconds = self.remaining_time % 60
        
        if self.is_running:
            return f"{status} - {minutes:02d}:{seconds:02d}"
        else:
            return f"{status} - 已暂停"

    def on_quit(self, icon, item=None):
        """退出应用"""
        self.is_running = False
        icon.stop()
        self.send_notification("你的休息小助手以退出，下次再见！")

    def update_menu(self):
        """更新系统托盘菜单"""
        menu = pystray.Menu(
            pystray.MenuItem(lambda text: self.get_status_text(), None, enabled=False),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("开始", self.start_timer, visible=lambda item: not self.is_running),
            pystray.MenuItem("暂停", self.stop_timer, visible=lambda item: self.is_running),
            pystray.MenuItem("重置", self.reset_timer),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("退出", self.on_quit)
        )
        
        if hasattr(self, 'icon'):
            self.icon.menu = menu

    def setup_tray(self):
        """设置系统托盘图标和菜单"""
        try:
            initial_icon = Image.open(self.icon_path)
        except Exception as e:
            print(f"无法加载图标文件: {e}")
            # 创建临时图标
            initial_icon = Image.new('RGBA', (64, 64), (255, 255, 255, 0))
            draw = ImageDraw.Draw(initial_icon)
            draw.ellipse([8, 8, 56, 56], fill='red', outline='darkred', width=2)
            draw.text((32, 32), "🍅", fill='white', anchor="mm", font_size=24)
        
        menu = pystray.Menu(
            pystray.MenuItem(lambda text: self.get_status_text(), None, enabled=False),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("开始", self.start_timer, visible=lambda item: not self.is_running),
            pystray.MenuItem("暂停", self.stop_timer, visible=lambda item: self.is_running),
            pystray.MenuItem("重置", self.reset_timer),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("退出", self.on_quit)
        )
        
        self.icon = pystray.Icon("pomodoro_timer", icon=initial_icon, menu=menu, title="番茄钟")
        self.update_tray_icon()

    def run(self):
        """启动应用"""
        timer_thread = threading.Thread(target=self.timer_loop, daemon=True)
        timer_thread.start()
        
        self.icon.run()

if __name__ == "__main__":
    timer = PomodoroTimer()
    timer.run()
