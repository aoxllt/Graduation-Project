# 设置环境变量
ROOTFS_URL="https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-full-amd64.tar.xz"
ROOTFS_FILE="kali-nethunter-rootfs-full-amd64.tar.xz"
INSTALL_DIR="$HOME/kali-nethunter"
KEX_SCRIPT_DIR="$INSTALL_DIR/kex"

# 检查并安装必要的依赖包
apt update && apt install -y proot tar wget axel

# 检查目录是否存在，如果存在则提示用户是否删除
if [ -d "$INSTALL_DIR" ]; then
    read -p "Kali NetHunter 已安装。是否删除现有文件并重新安装？(y/n): " confirm
    if [ "$confirm" = "y" ]; then
        rm -rf "$INSTALL_DIR"
    else
        echo "安装已取消"
        exit 1
    fi
fi

# 创建安装目录
mkdir -p "$INSTALL_DIR"

# 使用 axel 下载文件加速
cd "$INSTALL_DIR"
axel -a -n 10 "$ROOTFS_URL" -o "$ROOTFS_FILE"

# 验证文件是否下载成功
if [ ! -f "$ROOTFS_FILE" ]; then
    echo "下载失败，请检查网络连接"
    exit 1
fi

# 解压 RootFS
echo "正在解压 RootFS..."
proot --link2symlink tar -xJf "$ROOTFS_FILE" --preserve-permissions --same-owner || { echo "解压失败"; exit 1; }

# 创建启动脚本
echo "创建启动脚本..."
cat > $HOME/start-nethunter.sh <<- EOM
#!/bin/bash
cd $INSTALL_DIR
unset LD_PRELOAD
proot -0 -r $INSTALL_DIR -b /dev/ -b /proc/ -b /sys/ -b /data/data/com.termux/files/home:/root -w /root /bin/bash --login
EOM

chmod +x $HOME/start-nethunter.sh

# 提示用户如何启动
echo "安装完成！你可以使用以下命令启动 Kali NetHunter CLI:"
echo "$HOME/start-nethunter.sh"

# 可选：删除下载的压缩包以节省空间
read -p "是否删除下载的 RootFS 文件以节省空间？(y/n): " del_confirm
if [ "$del_confirm" = "y" ]; then
    rm -f "$ROOTFS_FILE"
    echo "文件已删除"
fi
