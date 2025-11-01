import sys
import json
from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QListWidget, QListWidgetItem, QLabel, 
                             QSpinBox, QPushButton, QColorDialog, QFrame, 
                             QFormLayout, QStackedWidget, QLineEdit, QComboBox,
                             QCheckBox, QSlider, QGroupBox, QScrollArea)
from PyQt5.QtCore import Qt, pyqtSignal
from PyQt5.QtGui import QColor, QPalette, QFont

class ColorPicker(QPushButton):
    colorChanged = pyqtSignal(str)
    
    def __init__(self, color, parent=None):
        super().__init__(parent)
        self.color = color
        self.update_color()
        self.clicked.connect(self.choose_color)
        
    def update_color(self):
        self.setStyleSheet(f"background-color: {self.color}; border: 1px solid black;")
        
    def choose_color(self):
        color = QColorDialog.getColor(QColor(self.color))
        if color.isValid():
            self.color = color.name()
            self.update_color()
            self.colorChanged.emit(self.color)

class SettingWidgetFactory:
    """工厂类，用于创建不同类型的设置控件"""
    
    @staticmethod
    def create_widget(setting_type, value, options=None):
        if setting_type == "spinbox":
            widget = QSpinBox()
            widget.setRange(options.get("min", 0), options.get("max", 100))
            widget.setValue(value)
            return widget
        elif setting_type == "lineedit":
            widget = QLineEdit()
            widget.setText(str(value))
            return widget
        elif setting_type == "combobox":
            widget = QComboBox()
            widget.addItems(options.get("items", []))
            widget.setCurrentText(str(value))
            return widget
        elif setting_type == "checkbox":
            widget = QCheckBox()
            widget.setChecked(bool(value))
            return widget
        elif setting_type == "slider":
            widget = QSlider(Qt.Horizontal)
            widget.setRange(options.get("min", 0), options.get("max", 100))
            widget.setValue(value)
            return widget
        elif setting_type == "colorpicker":
            widget = ColorPicker(value)
            return widget
        else:
            # 默认返回文本显示
            widget = QLabel(str(value))
            return widget

class SettingsPage(QWidget):
    """设置页面的基类"""
    
    def __init__(self, title, settings_config, parent=None):
        super().__init__(parent)
        self.title = title
        self.settings_config = settings_config
        self.widgets = {}
        self.init_ui()
    
    def init_ui(self):
        layout = QVBoxLayout()
        
        # 添加标题
        title_label = QLabel(self.title)
        title_font = QFont()
        title_font.setBold(True)
        title_font.setPointSize(16)
        title_label.setFont(title_font)
        layout.addWidget(title_label)
        
        # 添加分隔线
        line = QFrame()
        line.setFrameShape(QFrame.HLine)
        line.setFrameShadow(QFrame.Sunken)
        layout.addWidget(line)
        
        # 创建设置项
        scroll_area = QScrollArea()
        scroll_widget = QWidget()
        scroll_layout = QVBoxLayout(scroll_widget)
        
        for category, settings in self.settings_config.items():
            # 为每个类别创建分组框
            if category != "_general":
                group_box = QGroupBox(category)
                group_layout = QFormLayout()
                group_box.setLayout(group_layout)
                scroll_layout.addWidget(group_box)
                
                for key, config in settings.items():
                    label = QLabel(config.get("label", key))
                    widget = SettingWidgetFactory.create_widget(
                        config.get("type", "lineedit"),
                        config.get("value", ""),
                        config.get("options", {})
                    )
                    
                    # 保存控件引用以便后续获取值
                    self.widgets[key] = widget
                    
                    # 添加到布局
                    group_layout.addRow(label, widget)
            else:
                # 对于没有分组的设置项，直接添加到主布局
                form_layout = QFormLayout()
                for key, config in settings.items():
                    label = QLabel(config.get("label", key))
                    widget = SettingWidgetFactory.create_widget(
                        config.get("type", "lineedit"),
                        config.get("value", ""),
                        config.get("options", {})
                    )
                    
                    # 保存控件引用以便后续获取值
                    self.widgets[key] = widget
                    
                    # 添加到布局
                    form_layout.addRow(label, widget)
                
                scroll_layout.addLayout(form_layout)
        
        scroll_layout.addStretch(1)
        scroll_area.setWidget(scroll_widget)
        scroll_area.setWidgetResizable(True)
        layout.addWidget(scroll_area)
        
        self.setLayout(layout)
    
    def get_values(self):
        """获取页面中所有设置的值"""
        values = {}
        for key, widget in self.widgets.items():
            if isinstance(widget, QSpinBox):
                values[key] = widget.value()
            elif isinstance(widget, QLineEdit):
                values[key] = widget.text()
            elif isinstance(widget, QComboBox):
                values[key] = widget.currentText()
            elif isinstance(widget, QCheckBox):
                values[key] = widget.isChecked()
            elif isinstance(widget, QSlider):
                values[key] = widget.value()
            elif isinstance(widget, ColorPicker):
                values[key] = widget.color
            elif isinstance(widget, QLabel):
                values[key] = widget.text()
        return values

class SettingsManager:
    """管理设置的加载和保存"""
    
    def __init__(self, config_file="CONFIG.json"):
        self.config_file = config_file
        self.config = self.load_config()
    
    def load_config(self):
        try:
            with open(self.config_file, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"配置文件 {self.config_file} 不存在，使用默认配置")
            return self.get_default_config()
        except json.JSONDecodeError:
            print(f"配置文件 {self.config_file} 格式错误，使用默认配置")
            return self.get_default_config()
    
    def save_config(self):
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=4)
            return True
        except Exception as e:
            print(f"保存配置时出错: {e}")
            return False
    
    def get_default_config(self):
        """返回默认配置"""
        return {
            "pomodoro": {
                "work_duration": 1200,
                "break_duration": 20
            },
            "colors": {
                "al": "#00000000",
                "bg": "#64646480",
                "bga": "#00000000",
                "fg": "#e5e5e5ff",
                "ac": "#bf616aff",
                "se": "#e5e5e5ff"
            }
        }
    
    def get_settings_pages_config(self):
        """返回设置页面的配置"""
        return {
            "番茄钟设置": {
                "计时设置": {
                    "work_duration": {
                        "label": "工作时间 (秒)",
                        "type": "spinbox",
                        "value": self.config["pomodoro"].get("work_duration", 1200),
                        "options": {"min": 60, "max": 3600}
                    },
                    "break_duration": {
                        "label": "休息时间 (秒)",
                        "type": "spinbox",
                        "value": self.config["pomodoro"].get("break_duration", 20),
                        "options": {"min": 5, "max": 600}
                    }
                }
            },
            "外观设置": {
                "颜色设置": {
                    "al": {
                        "label": "AL 颜色",
                        "type": "colorpicker",
                        "value": self.config["colors"].get("al", "#00000000")
                    },
                    "bg": {
                        "label": "BG 颜色",
                        "type": "colorpicker",
                        "value": self.config["colors"].get("bg", "#64646480")
                    },
                    "bga": {
                        "label": "BGA 颜色",
                        "type": "colorpicker",
                        "value": self.config["colors"].get("bga", "#00000000")
                    },
                    "fg": {
                        "label": "FG 颜色",
                        "type": "colorpicker",
                        "value": self.config["colors"].get("fg", "#e5e5e5ff")
                    },
                    "ac": {
                        "label": "AC 颜色",
                        "type": "colorpicker",
                        "value": self.config["colors"].get("ac", "#bf616aff")
                    },
                    "se": {
                        "label": "SE 颜色",
                        "type": "colorpicker",
                        "value": self.config["colors"].get("se", "#e5e5e5ff")
                    }
                }
            },
            "高级设置": {
                "_general": {
                    "auto_save": {
                        "label": "自动保存",
                        "type": "checkbox",
                        "value": True
                    }
                }
            }
        }

class SettingsWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.settings_manager = SettingsManager()
        self.pages = {}
        self.init_ui()
        
    def init_ui(self):
        self.setWindowTitle('AronaOS设置')
        self.setFixedSize(900, 600)
        
        # 主布局
        main_widget = QWidget()
        main_layout = QHBoxLayout()
        main_widget.setLayout(main_layout)
        self.setCentralWidget(main_widget)
        
        # 左侧边栏
        self.sidebar = QListWidget()
        self.sidebar.setFixedWidth(150)
        main_layout.addWidget(self.sidebar)
        
        # 右侧内容区域
        self.content_area = QStackedWidget()
        main_layout.addWidget(self.content_area)
        
        # 创建设置页面
        self.create_settings_pages()
        
        # 连接信号
        self.sidebar.currentRowChanged.connect(self.change_page)
        
        # 默认选择第一项
        if self.sidebar.count() > 0:
            self.sidebar.setCurrentRow(0)
        
        # 添加保存按钮
        save_button = QPushButton("保存设置")
        save_button.clicked.connect(self.save_settings)
        self.statusBar().addPermanentWidget(save_button)
    
    def create_settings_pages(self):
        """根据配置创建所有设置页面"""
        pages_config = self.settings_manager.get_settings_pages_config()
        
        for title, settings_config in pages_config.items():
            # 添加到侧边栏
            self.sidebar.addItem(title)
            
            # 创建设置页面
            page = SettingsPage(title, settings_config)
            self.content_area.addWidget(page)
            self.pages[title] = page
    
    def change_page(self, index):
        """切换设置页面"""
        if 0 <= index < self.content_area.count():
            self.content_area.setCurrentIndex(index)
    
    def save_settings(self):
        """保存所有设置"""
        # 收集所有页面的设置值
        for title, page in self.pages.items():
            values = page.get_values()
            
            # 根据页面标题更新对应的配置部分
            if title == "番茄钟设置":
                self.settings_manager.config["pomodoro"].update(values)
            elif title == "外观设置":
                self.settings_manager.config["colors"].update(values)
            elif title == "高级设置":
                # 高级设置可能需要特殊处理
                if "advanced" not in self.settings_manager.config:
                    self.settings_manager.config["advanced"] = {}
                self.settings_manager.config["advanced"].update(values)
        
        import implement_settings
        implement_settings.apply_settings()
        
        # 保存配置到文件
        if self.settings_manager.save_config():
            self.statusBar().showMessage("设置已保存", 3000)
        else:
            self.statusBar().showMessage("保存设置失败", 3000)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = SettingsWindow()
    window.show()
    sys.exit(app.exec_())