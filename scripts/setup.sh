#!/bin/bash
# 服务器环境初始化脚本

set -e

echo "========================================="
echo "初始化服务器环境"
echo "========================================="

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# 检查是否为 root
if [[ $EUID -ne 0 ]]; then
   echo "请使用 root 用户运行此脚本"
   exit 1
fi

# 1. 更新系统
info "更新系统包..."
apt-get update
apt-get upgrade -y

# 2. 安装基础工具
info "安装基础工具..."
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    unzip \
    software-properties-common \
    ca-certificates \
    gnupg \
    lsb-release

# 3. 安装 Docker
info "安装 Docker..."
if ! command -v docker &> /dev/null; then
    # 添加 Docker 官方 GPG 密钥
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # 添加 Docker 仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装 Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # 启动 Docker
    systemctl start docker
    systemctl enable docker
    
    info "Docker 安装完成"
else
    info "Docker 已安装"
fi

# 4. 安装 Docker Compose
info "检查 Docker Compose..."
if ! docker compose version &> /dev/null; then
    info "Docker Compose 插件未安装，正在安装..."
    apt-get install -y docker-compose-plugin
else
    info "Docker Compose 已安装"
fi

# 5. 配置防火墙
info "配置防火墙..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
fi

# 6. 创建应用目录
info "创建应用目录..."
mkdir -p /opt/app
mkdir -p /opt/backups
mkdir -p /opt/logs

# 7. 创建应用用户
info "创建应用用户..."
if ! id "appuser" &>/dev/null; then
    useradd -r -s /bin/bash -d /opt/app appuser
    usermod -aG docker appuser
fi

# 8. 设置目录权限
chown -R appuser:appuser /opt/app
chown -R appuser:appuser /opt/backups
chown -R appuser:appuser /opt/logs

# 9. 配置系统参数
info "优化系统参数..."
cat >> /etc/sysctl.conf <<EOF
# 网络优化
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.ip_local_port_range = 10000 65000

# 文件描述符
fs.file-max = 65536
EOF

sysctl -p

# 10. 设置日志轮转
info "配置日志轮转..."
cat > /etc/logrotate.d/app <<EOF
/opt/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 appuser appuser
}
EOF

echo "========================================="
echo -e "${GREEN}环境初始化完成！${NC}"
echo "========================================="
echo "Docker 版本: $(docker --version)"
echo "Docker Compose 版本: $(docker compose version)"
echo "应用目录: /opt/app"
echo "========================================="
