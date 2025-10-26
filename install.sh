#!/usr/bin/env bash

# 欢迎信息
echo "=== AronaOS 安装脚本 ==="

# 前置询问所有选项
read -p "是否安装AronaOS？(y/n) " install_arona
if [[ $install_arona == "n" ]]; then
    echo "已取消安装"
    exit 0
fi

read -p "是否更改镜像源？(y/n) " change_mirror
read -p "是否安装图标？(y/n) " install_icons
read -p "是否配置sddm？(y/n) " config_sddm
read -p "是否编译linux内核（耗时很长，请谨慎选择）？(y/n) " compile_kernel
read -p "是否更改/etc/os-release 文件？(y/n) " change_os_release
read -p "是否更改GURB配置？(y/n) " change_grub

# 确认安装
echo ""
echo "=== 安装摘要 ==="
echo "更改镜像源: $change_mirror"
echo "安装图标: $install_icons"
echo "配置sddm: $config_sddm"
echo "编译内核: $compile_kernel"
echo "更改os-release: $change_os_release"
echo "更改GURB配置: $change_grub"
echo ""

read -p "确认开始安装？(y/n) " confirm_install
if [[ $confirm_install == "n" ]]; then
    echo "已取消安装"
    exit 0
fi

echo "开始安装AronaOS..."

# 更改镜像源
if [[ $change_mirror == "y" ]]; then
    echo "更改镜像源..."
    echo -e "Server = https://mirrors.tuna.tsinghua.edu.cn/manjaro/stable/\$repo/\$arch\nServer = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch" | sudo tee /etc/pacman.d/mirrorlist
    sudo pacman -Syyu --noconfirm
    echo "镜像源已更改为清华大学镜像源"
fi

# 添加archlinuxcn镜像源
echo "添加archlinuxcn镜像源..."
echo -e "[archlinuxcn]\nServer = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch" | sudo tee -a /etc/pacman.conf
sudo pacman -Syyu --noconfirm

# 安装依赖
echo "安装系统依赖..."
sudo pacman -S git vim zsh curl wget yay fcitx5 fcitx5-configtool fcitx5-qt fcitx5-gtk fcitx5-chinese-addons fcitx5-material-color --noconfirm
sudo pacman -S hyprland swww hyprlock hyprcursor hyprgraphics hyprland-qt-support hyprland-qtutils hyprlang hyprutils hyprwayland-scanner --noconfirm
sudo pacman -S waybar rofi nvim thunar mpv kitty fastfetch dunst cava btop cliphist grim slurp base-devel playerctl --noconfirm
sudo pacman -S ttf-dejavu ttf-liberation ttf-font-awesome ttf-jetbrains-mono-nerd --noconfirm

echo "安装AUR软件..."
yay -S clash-verge-rev-bin linuxqq qqmusic wechat --noconfirm

echo "安装依赖完成"

# 转移配置文件
echo "正在配置系统..."
cp -r ./config ~/.config 

# 配置zsh
echo "配置zsh..."
sh -c "$(curl -fsSL https://gitee.com/mirrors_sigma/zinit/raw/master/zinit-install.zsh)"
cp ./.zshrc ~/.zshrc
chsh -s /bin/zsh
echo "zsh 已配置"

# 安装字体
echo "安装字体..."
cp ./fonts/* ~/.local/share/fonts/
fc-cache -f -v
echo "字体已安装"

# 复制icons
echo "安装图标..."
cp -r ./.icons ~/.icons
echo "icons 已安装"

# 安装图标主题
if [[ $install_icons == "y" ]]; then
    echo "安装Papirus图标主题..."
    wget -qO- https://git.io/papirus-icon-theme-install | sh
    wget -qO- https://git.io/papirus-icon-theme-install | env DESTDIR="$HOME/.icons" sh
    wget -qO- https://git.io/papirus-icon-theme-install | env DESTDIR="$HOME/.local/share/icons" sh
    echo "图标主题已安装"
fi

# 复制wallpaper
echo "安装壁纸..."
cp -r ./wallpaper ~/wallpaper
echo "wallpaper 已安装"

# 配置sddm
if [[ $config_sddm == "y" ]]; then
    echo "配置sddm..."
    cp -r ./arona-sddm-login /usr/share/sddm/themes/arona-sddm-login
    sudo sed -i 's/Current=/Current=arona-sddm-login/' /etc/sddm.conf.d/arona-sddm.conf
    echo "sddm 已配置"
fi

# 编译linux内核
if [[ $compile_kernel == "y" ]]; then
    read -p "编译内核可能需要数小时，确认继续？(y/n) " confirm_kernel
    if [[ $confirm_kernel == "y" ]]; then
        echo "开始编译linux内核..."
        
        wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.17.tar.xz 

        tar -xvf linux-6.17.tar.xz

        cd linux-6.17

        cp ../.config .config

        make -j$(nproc)

        # 安装模块
        sudo make modules_install

        # 获取内核版本
        KERNEL_VERSION=$(make kernelrelease)
        echo "内核版本: $KERNEL_VERSION"

        # 检查模块目录
        echo "检查模块目录:"
        ls -la /lib/modules/ | grep "$KERNEL_VERSION"

        # 复制内核文件
        sudo cp arch/x86/boot/bzImage /boot/vmlinuz-$KERNEL_VERSION
        sudo cp System.map /boot/System.map-$KERNEL_VERSION
        sudo cp .config /boot/config-$KERNEL_VERSION

        # 生成 initramfs
        echo "生成 initramfs..."
        sudo mkinitcpio -k $KERNEL_VERSION -g /boot/initramfs-$KERNEL_VERSION.img

        # 更新 GRUB
        sudo grub-mkconfig -o /boot/grub/grub.cfg

        echo "内核编译完成"
    else
        echo "已跳过内核编译"
    fi
fi

# 更改/etc/os-release 文件
if [[ $change_os_release == "y" ]]; then
    echo "更改/etc/os-release 文件..."
    sudo sed -i 's/NAME=.*$/NAME="AronaOS"/' /etc/os-release
    sudo sed -i 's/PRETTY_NAME=.*$/PRETTY_NAME="AronaOS"/' /etc/os-release
    echo "已更改/etc/os-release 文件"
fi

# 更改GURB配置
if [[ $change_grub == "y" ]]; then
    echo "更改GURB配置..."
    # 修改GRUB_DISTRIBUTOR
    sudo sed -i 's/GRUB_DISTRIBUTOR=.*$/GRUB_DISTRIBUTOR="AronaOS"/' /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    echo "已更改GURB配置"
fi

echo ""
echo "=== AronaOS 安装完成 ==="
echo "请重新启动系统以应用所有更改"