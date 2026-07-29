#!/bin/bash
set -e

MODE="${1:-win11}"
TARGET="${2:-all}"

MIN_SIZE_GB=50

WINDOWS_DIR="windows"
UBUNTU_DIR="ubuntu"

WINDOWS_STORAGE_SUBDIR="windows/docker-windows-storage"
UBUNTU_STORAGE_SUBDIR="ubuntu/ubuntu-data"

WINDOWS_USERNAME="${WINDOWS_USERNAME:-MASTER}"
WINDOWS_PASSWORD="${WINDOWS_PASSWORD:-admin@123}"
WINDOWS_VERSION="${WINDOWS_VERSION:-11}"
WINDOWS_RAM_SIZE="${WINDOWS_RAM_SIZE:-4G}"
WINDOWS_CPU_CORES="${WINDOWS_CPU_CORES:-4}"
WINDOWS_DISK_SIZE="${WINDOWS_DISK_SIZE:-64G}"
WINDOWS_DISK2_SIZE="${WINDOWS_DISK2_SIZE:-10G}"

UBUNTU_ROOT_PASSWORD="${ROOT_PASSWORD:-root}"

CURRENT_DIR="$(pwd)"

WINDOWS_PATH="$CURRENT_DIR/$WINDOWS_DIR"
UBUNTU_PATH="$CURRENT_DIR/$UBUNTU_DIR"

WINDOWS_COMPOSE_FILE="$WINDOWS_PATH/docker-compose.yml"
UBUNTU_COMPOSE_FILE="$UBUNTU_PATH/docker-compose.yml"

backup_file() {
    local file="$1"

    if [ -f "$file" ]; then
        local backup="${file}.bak.$(date +%s)"
        mv "$file" "$backup"
        echo "💾 已备份原文件: $backup"
    fi
}

detect_compose_cmd() {
    if docker compose version &>/dev/null; then
        COMPOSE_CMD="docker compose"
    elif docker-compose version &>/dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        echo "❌ 未检测到 docker compose 或 docker-compose，请安装 Docker"
        exit 1
    fi
}

detect_large_storage() {
    echo "🔍 检测大容量数据盘..."

    TMP_DEV=""
    TMP_SIZE_GB=0

    if mountpoint -q /tmp 2>/dev/null; then
        TMP_DEV=$(findmnt -n -o SOURCE -T /tmp 2>/dev/null || df -P /tmp | awk 'NR==2{print $1}')
        TMP_SIZE_KB=$(df -P /tmp | awk 'NR==2{print $2}')
        TMP_SIZE_GB=$((TMP_SIZE_KB / 1024 / 1024))
    fi

    readarray -t CANDIDATES < <(
        df -P -x tmpfs -x devtmpfs -x overlay -x proc -x sysfs -x cgroup2 -x cgroup 2>/dev/null | awk 'NR>1 {
            if ($1 ~ /^\/dev\/loop/ || $1 ~ /^\/dev\/ram/) next
            if ($6 == "/" || $6 == "/vscode" || $6 == "/workspaces" || $6 == "/boot") next
            size_gb = int($2 / 1024 / 1024)
            if (size_gb >= 50) print size_gb, $1, $6
        }' | sort -rn
    )

    TARGET_MOUNT=""
    TARGET_DEV=""
    TARGET_SIZE_GB=0

    if [ -n "$TMP_DEV" ] && [[ "$TMP_DEV" == /dev/* ]] && [ "$TMP_SIZE_GB" -ge "$MIN_SIZE_GB" ]; then
        TARGET_MOUNT="/tmp"
        TARGET_DEV="$TMP_DEV"
        TARGET_SIZE_GB="$TMP_SIZE_GB"
        echo "✅ 使用 /tmp（设备: $TMP_DEV, 容量: ${TMP_SIZE_GB}G）"
    else
        if [ ${#CANDIDATES[@]} -eq 0 ]; then
            TARGET_MOUNT="$CURRENT_DIR"
            TARGET_DEV="$(findmnt -n -o SOURCE -T "$CURRENT_DIR" 2>/dev/null || df -P "$CURRENT_DIR" | awk 'NR==2{print $1}')"
            TARGET_SIZE_GB="$(df -P "$CURRENT_DIR" | awk 'NR==2{print int($2/1024/1024)}')"
            echo "⚠️  未检测到 >=${MIN_SIZE_GB}G 的数据盘，改用当前目录: $TARGET_MOUNT（设备: $TARGET_DEV, 容量: ${TARGET_SIZE_GB}G）"
        else
            read -r MAX_GB MAX_DEV MAX_MNT <<< "${CANDIDATES[0]}"
            TARGET_MOUNT="$MAX_MNT"
            TARGET_DEV="$MAX_DEV"
            TARGET_SIZE_GB="$MAX_GB"
            echo "✅ 使用数据盘: $MAX_DEV -> $TARGET_MOUNT (${MAX_GB}G)"
        fi
    fi
}

prepare_windows_storage() {
    detect_large_storage

    WINDOWS_STORAGE_PATH="$TARGET_MOUNT/$WINDOWS_STORAGE_SUBDIR"
    mkdir -p "$WINDOWS_STORAGE_PATH"

    echo "📂 Windows Storage 路径: $WINDOWS_STORAGE_PATH"
}

prepare_ubuntu_storage() {
    detect_large_storage

    UBUNTU_STORAGE_PATH="$TARGET_MOUNT/$UBUNTU_STORAGE_SUBDIR"
    mkdir -p "$UBUNTU_STORAGE_PATH"

    echo "📂 Ubuntu Storage 路径: $UBUNTU_STORAGE_PATH"
}

start_windows() {
    echo "🪟 模式: Windows 11"

    mkdir -p "$WINDOWS_PATH"

    prepare_windows_storage
    backup_file "$WINDOWS_COMPOSE_FILE"

    AVAIL_GB=$(df -P "$TARGET_MOUNT" | awk 'NR==2{print int($4/1024/1024)}')
    echo "   可用空间: ${AVAIL_GB}G"

    TOTAL_NEEDED=74

    if [ "$AVAIL_GB" -lt "$TOTAL_NEEDED" ]; then
        echo ""
        echo "⚠️  警告: 可用空间仅 ${AVAIL_GB}G，但虚拟磁盘配置了 ${TOTAL_NEEDED}G"
        echo "    qcow2 是稀疏格式，实际占用取决于 Windows 内部写入量"
        echo "    如果 Windows 内部使用超过 ${AVAIL_GB}G，磁盘将会写满"
        echo ""
    fi

    cat > "$WINDOWS_COMPOSE_FILE" << EOF
services:
  windows:
    image: dockurr/windows
    container_name: windows
    environment:
      VERSION: "${WINDOWS_VERSION}"
      USERNAME: "${WINDOWS_USERNAME}"
      PASSWORD: "${WINDOWS_PASSWORD}"
      RAM_SIZE: "${WINDOWS_RAM_SIZE}"
      CPU_CORES: "${WINDOWS_CPU_CORES}"
      DISK_SIZE: "${WINDOWS_DISK_SIZE}"
      DISK2_SIZE: "${WINDOWS_DISK2_SIZE}"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    ports:
      - "8006:8006"
      - "3389:3389/tcp"
      - "3389:3389/udp"
    volumes:
      - "${WINDOWS_STORAGE_PATH}:/storage"
    stop_grace_period: 2m
EOF

    echo "✅ 已生成: $WINDOWS_COMPOSE_FILE"

    detect_compose_cmd

    echo ""
    echo "🚀 执行: $COMPOSE_CMD -f $WINDOWS_COMPOSE_FILE up"
    echo ""

    $COMPOSE_CMD -f "$WINDOWS_COMPOSE_FILE" up

    echo ""
    echo "🎉 启动完成"
    echo "   管理界面: http://localhost:8006"
    echo "   RDP 连接: localhost:3389"
    echo "   用户名: ${WINDOWS_USERNAME}"
    echo "   密码: ${WINDOWS_PASSWORD}"
    echo "   配置目录: $WINDOWS_PATH"
    echo "   数据存储: $WINDOWS_STORAGE_PATH"
    echo "   宿主机设备: $TARGET_DEV"
}

start_ubuntu() {
    echo "🐧 模式: Ubuntu Desktop"

    mkdir -p "$UBUNTU_PATH"

    prepare_ubuntu_storage
    backup_file "$UBUNTU_PATH/Dockerfile"
    backup_file "$UBUNTU_PATH/entrypoint.sh"
    backup_file "$UBUNTU_COMPOSE_FILE"

    AVAIL_GB=$(df -P "$TARGET_MOUNT" | awk 'NR==2{print int($4/1024/1024)}')
    echo "   可用空间: ${AVAIL_GB}G"

    cat > "$UBUNTU_PATH/Dockerfile" << 'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      shellinabox \
      openssh-server \
      sudo \
      vim \
      nano \
      curl \
      wget \
      ca-certificates \
      net-tools \
      iproute2 \
      locales \
      tzdata \
      procps \
      dbus-x11 \
      xrdp \
      xfce4 \
      xfce4-terminal && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /run/sshd /workspace && \
    printf '\nPermitRootLogin yes\nPasswordAuthentication yes\n' >> /etc/ssh/sshd_config && \
    echo "startxfce4" > /root/.xsession && \
    chmod +x /root/.xsession && \
    adduser xrdp ssl-cert

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 3389 4200

CMD ["/entrypoint.sh"]
EOF

    cat > "$UBUNTU_PATH/entrypoint.sh" << 'EOF'
#!/bin/bash
set -e

: "${ROOT_PASSWORD:=root}"

echo "🔐 设置 root 密码..."
echo "root:${ROOT_PASSWORD}" | chpasswd

echo "🔑 生成 SSH host keys..."
ssh-keygen -A

echo "📁 准备运行目录..."
mkdir -p /var/run/sshd
mkdir -p /var/run/xrdp
mkdir -p /var/log/xrdp

rm -f /var/run/xrdp/xrdp.pid
rm -f /var/run/xrdp/xrdp-sesman.pid

echo "🚀 启动 SSH 服务，外部端口 8022，容器内端口 22..."
/usr/sbin/sshd

echo "🚀 启动 Web 终端，端口 4200..."
/usr/bin/shellinaboxd \
  -t \
  -p 4200 \
  -s "/:LOGIN" &

echo "🚀 启动 XRDP 会话服务..."
/usr/sbin/xrdp-sesman

echo "✅ Ubuntu 容器已启动"
echo "   RDP: 3389"
echo "   SSH: 8022"
echo "   Web Terminal: 4200"

exec /usr/sbin/xrdp --nodaemon
EOF

    chmod +x "$UBUNTU_PATH/entrypoint.sh"

    cat > "$UBUNTU_COMPOSE_FILE" << EOF
services:
  ubuntu:
    build: .
    container_name: ubuntu-web
    environment:
      ROOT_PASSWORD: "${UBUNTU_ROOT_PASSWORD}"
    ports:
      - "3389:3389"
      - "8022:22"
      - "4200:4200"
    volumes:
      - "${UBUNTU_STORAGE_PATH}:/workspace"
    restart: unless-stopped
EOF

    echo "✅ 已生成: $UBUNTU_PATH/Dockerfile"
    echo "✅ 已生成: $UBUNTU_PATH/entrypoint.sh"
    echo "✅ 已生成: $UBUNTU_COMPOSE_FILE"
    echo "📂 Ubuntu 数据目录: $UBUNTU_STORAGE_PATH"

    detect_compose_cmd

    echo ""
    echo "🚀 执行: $COMPOSE_CMD -f $UBUNTU_COMPOSE_FILE up --build"
    echo ""

    $COMPOSE_CMD -f "$UBUNTU_COMPOSE_FILE" up --build

    echo ""
    echo "🎉 启动完成"
    echo "   RDP: localhost:3389"
    echo "   SSH: localhost:8022"
    echo "   Web 终端: http://localhost:4200"
    echo "   用户名: root"
    echo "   密码: ${UBUNTU_ROOT_PASSWORD}"
    echo "   配置目录: $UBUNTU_PATH"
    echo "   数据目录: $UBUNTU_STORAGE_PATH"
    echo "   宿主机设备: $TARGET_DEV"
}

stop_windows() {
    echo "🛑 停止 Windows 容器..."

    if [ -f "$WINDOWS_COMPOSE_FILE" ]; then
        detect_compose_cmd
        $COMPOSE_CMD -f "$WINDOWS_COMPOSE_FILE" down 2>/dev/null || true
    fi

    docker stop windows 2>/dev/null || true
    docker rm windows 2>/dev/null || true

    echo "✅ Windows 容器已停止"
}

stop_ubuntu() {
    echo "🛑 停止 Ubuntu 容器..."

    if [ -f "$UBUNTU_COMPOSE_FILE" ]; then
        detect_compose_cmd
        $COMPOSE_CMD -f "$UBUNTU_COMPOSE_FILE" down 2>/dev/null || true
    fi

    docker stop ubuntu-web 2>/dev/null || true
    docker rm ubuntu-web 2>/dev/null || true

    echo "✅ Ubuntu 容器已停止"
}

stop_target() {
    case "$TARGET" in
        all)
            stop_windows
            stop_ubuntu
            ;;
        win|win11|windows)
            stop_windows
            ;;
        ubuntu|linux)
            stop_ubuntu
            ;;
        *)
            echo "❌ 不支持的停止目标: $TARGET"
            echo ""
            echo "用法:"
            echo "  bash start.sh stop"
            echo "  bash start.sh stop win11"
            echo "  bash start.sh stop ubuntu"
            exit 1
            ;;
    esac
}

show_usage() {
    echo "用法:"
    echo "  bash start.sh"
    echo "  bash start.sh win11"
    echo "  bash start.sh ubuntu"
    echo "  bash start.sh stop"
    echo "  bash start.sh stop win11"
    echo "  bash start.sh stop ubuntu"
    echo ""
    echo "配置目录:"
    echo "  Windows 配置目录: ./windows"
    echo "  Ubuntu 配置目录: ./ubuntu"
    echo ""
    echo "数据目录:"
    echo "  Windows 数据目录: 大容量盘/windows/docker-windows-storage"
    echo "  Ubuntu 数据目录: 大容量盘/ubuntu/ubuntu-data"
    echo ""
    echo "环境变量:"
    echo "  WINDOWS_USERNAME=MASTER"
    echo "  WINDOWS_PASSWORD=admin@123"
    echo "  WINDOWS_VERSION=11"
    echo "  WINDOWS_RAM_SIZE=4G"
    echo "  WINDOWS_CPU_CORES=4"
    echo "  WINDOWS_DISK_SIZE=64G"
    echo "  WINDOWS_DISK2_SIZE=10G"
    echo "  ROOT_PASSWORD=root"
}

case "$MODE" in
    win|win11|windows)
        start_windows
        ;;
    ubuntu|linux)
        start_ubuntu
        ;;
    stop)
        stop_target
        ;;
    help|-h|--help)
        show_usage
        ;;
    *)
        echo "❌ 不支持的模式: $MODE"
        echo ""
        show_usage
        exit 1
        ;;
esac
