#!/bin/bash

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "请以root权限运行此脚本"
    exit 1
fi

# 获取系统内存大小（GB）
mem_size=$(free -g | awk '/^Mem:/{print $2}')

# 对于小于1GB的内存特殊处理
if [ "$mem_size" -lt 1 ]; then
    echo "检测到内存小于1GB，将创建1GB的swap空间"
    swap_size=1
elif [ "$mem_size" -le 2 ]; then
    swap_size=$((mem_size * 2))
elif [ "$mem_size" -le 8 ]; then
    swap_size=$mem_size
else
    swap_size=8
fi

echo "系统内存: ${mem_size}GB"
echo "将创建 ${swap_size}GB 的swap空间"

# 检查是否已存在swap文件
if [ -f /swapfile ]; then
    echo "检测到已存在swap文件，正在关闭..."
    swapoff /swapfile
    rm /swapfile
fi

# 创建swap文件（使用dd命令替代fallocate）
echo "正在创建 ${swap_size}GB swap文件..."
dd if=/dev/zero of=/swapfile bs=1024 count=$((swap_size * 1024 * 1024))

# 设置权限
chmod 600 /swapfile

# 设置swap
mkswap /swapfile
swapon /swapfile

# 检查是否需要添加到fstab
if ! grep -q "/swapfile none swap sw 0 0" /etc/fstab; then
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi

# 显示当前swap状态
echo "Swap配置完成！当前状态："
swapon --show
free -h

echo "系统重启后swap将自动启用"
