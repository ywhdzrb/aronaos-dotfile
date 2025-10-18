#!/usr/bin/env bash

dir="~/.config/hypr"
uptime=$(uptime -p | sed -e 's/up //g')

rofi_command="rofi -no-config -theme $dir/powermenur.rasi"

shutdown=" 关机"
reboot=" 重启"
lock=" 锁定"
suspend=" 睡眠"
logout=" 注销"

options="$lock\n$suspend\n$logout\n$reboot\n$shutdown"

chosen="$(echo -e "$options" | $rofi_command -p "系统运行时间: $uptime" -dmenu -selected-row 0)"
case $chosen in
$shutdown)
    systemctl poweroff
    ;;
$reboot)
    systemctl reboot
    ;;
$lock)
    # 直接使用 hyprlock 锁定屏幕
    hyprlock
    ;;
$suspend)
    # mpc -q pause
    # amixer set Master mute
    hyprlock && systemctl suspend
    ;;
$logout)
    # 直接使用 hyprctl 退出 Hyprland
    hyprctl dispatch exit
    ;;
esac