#!/usr/bin/env bash

# 安装依赖

# 询问用户是否更改镜像源
read -p "是否更改镜像源？(y/n) " change_mirror

if [[ $change_mirror == "y" ]]; then
    # 更改镜像源
    echo "更改镜像源..."
    # 这里可以添加更改镜像源的代码
    echo -e "Server = https://mirrors.tuna.tsinghua.edu.cn/manjaro/stable/\$repo/\$arch\nServer = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch" | sudo tee /etc/pacman.d/mirrorlist
    # 更新镜像源
    sudo pacman -Syyu --noconfirm
    echo "镜像源已更改为清华大学镜像源"
fi

# 添加archlinuxcn镜像源
echo -e "[archlinuxcn]\nServer = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch" | sudo tee -a /etc/pacman.conf
sudo pacman -Syyu --noconfirm

# 安装依赖
sudo pacman -S git vim zsh curl wget yay fcitx5 fcitx5-configtool fcitx5-qt fcitx5-gtk fcitx5-chinese-addons fcitx5-material-color --noconfirm
sudo pacman -S hyprland swww hyprlock hyprcursor hyprgraphics hyprland-qt-support hyprland-qtutils hyprlang hyprutils hyprwayland-scanner --noconfirm
sudo pacman -S waybar rofi nvim thunar mpv kitty fastfetch dunst cava btop cliphist grim slurp base-devel--noconfirm
sudo pacman -S ttf-dejavu ttf-liberation ttf-font-awesome ttf-jetbrains-mono-nerd --noconfirm
yay -S clash-verge-rev-bin --noconfirm

echo "安装依赖完成"

# 转移配置文件
echo "正在配置"

cp -r ./config ~/.config 

# zsh
sh -c "$(curl -fsSL https://gitee.com/mirrors_sigma/zinit/raw/master/zinit-install.zsh)"
cp ./.zshrc ~/.zshrc
chsh -s /bin/zsh
echo "zsh 已配置"

# 安装字体
cp ./fonts/* ~/.local/share/fonts/
fc-cache -f -v
echo "字体已安装"

# 复制icons
cp -r ./.icons ~/.icons
# cp -r ./icons /usr/share/icons
echo "icons 已安装"

# 安装图标
# 询问用户是否安装图标
read -p "是否安装图标？(y/n) " install_icons

if [[ $install_icons == "y" ]]; then
    # 安装图标
    echo "安装图标..."
    wget -qO- https://git.io/papirus-icon-theme-install | sh
    wget -qO- https://git.io/papirus-icon-theme-install | env DESTDIR="$HOME/.icons" sh
    wget -qO- https://git.io/papirus-icon-theme-install | env DESTDIR="$HOME/.local/share/icons" sh
    echo "图标已安装"
fi

# 复制wallpaper
cp -r ./wallpaper ~/wallpaper
echo "wallpaper 已安装"

# 是否编译linux内核
read -p "是否编译linux内核（没事不要编译，应为耗的时间长）？(y/n) " compile_kernel

if [[ $compile_kernel == "y" ]]; then
    # 编译linux内核
    echo "编译linux内核..."
    
    wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.17.tar.xz 

    tar -xvf linux-6.17.tar.xz

    cd linux-6.17

    cp ../.config .config

    make -j$(nproc)

    # 2. 安装模块
    sudo make modules_install

    # 3. 获取内核版本
    KERNEL_VERSION=$(make kernelrelease)
    echo "内核版本: $KERNEL_VERSION"

    # 4. 检查模块目录
    echo "检查模块目录:"
    ls -la /lib/modules/ | grep "$KERNEL_VERSION"

    # 5. 复制内核文件
    sudo cp arch/x86/boot/bzImage /boot/vmlinuz-$KERNEL_VERSION
    sudo cp System.map /boot/System.map-$KERNEL_VERSION
    sudo cp .config /boot/config-$KERNEL_VERSION

    # 6. 生成 initramfs
    echo "生成 initramfs..."
    sudo mkinitcpio -k $KERNEL_VERSION -g /boot/initramfs-$KERNEL_VERSION.img

    # 7. 更新 GRUB
    sudo grub-mkconfig -o /boot/grub/grub.cfg

    echo "编译完成"
fi

# 询问是否更改/etc/os-release 文件
read -p "是否更改/etc/os-release 文件？(y/n) " change_os_release

if [[ $change_os_release == "y" ]]; then
    # 更改/etc/os-release 文件
    echo "更改/etc/os-release 文件..."
    # 把NAME和PRETTY_NAME 改为AronaOS
    sudo sed -i 's/NAME=.*$/NAME="AronaOS"/' /etc/os-release
    sudo sed -i 's/PRETTY_NAME=.*$/PRETTY_NAME="AronaOS"/' /etc/os-release

    echo "已更改/etc/os-release 文件"
fi


