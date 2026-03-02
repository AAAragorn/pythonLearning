#!/bin/bash
set -e

echo "=========================================="
echo "服务器环境初始化脚本"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    print_error "请使用 root 用户运行此脚本"
    exit 1
fi

# 更新系统
print_info "更新系统包..."
apt-get update
apt-get upgrade -y

# 安装基础工具
print_info "安装基础工具..."
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    ufw \
    fail2ban \
    ca-certificates \
    gnupg \
    lsb-release

# 安装 Docker
print_info "安装 Docker..."
if ! command -v docker &> /dev/null; then
    # 添加 Docker 官方 GPG 密钥
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # 设置 Docker 仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装 Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # 启动 Docker 服务
    systemctl start docker
    systemctl enable docker
    
    print_info "Docker 安装完成"
else
    print_info "Docker 已安装"
fi

# 安装 Docker Compose
print_info "安装 Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_info "Docker Compose 安装完成"
else
    print_info "Docker Compose 已安装"
fi

# 配置防火墙
print_info "配置防火墙..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw status

# 配置 fail2ban
print_info "配置 fail2ban..."
systemctl start fail2ban
systemctl enable fail2ban

# 创建应用目录
print_info "创建应用目录..."
mkdir -p /opt/app
mkdir -p /opt/backups
mkdir -p /opt/logs

# 创建部署用户
print_info "创建部署用户..."
if ! id -u deploy &> /dev/null; then
    useradd -m -s /bin/bash deploy
    usermod -aG docker deploy
    print_info "用户 deploy 创建完成"
else
    print_info "用户 deploy 已存在"
fi

# 设置目录权限
chown -R deploy:deploy /opt/app
chown -R deploy:deploy /opt/backups
chown -R deploy:deploy /opt/logs

# 配置系统限制
print_info "配置系统限制..."
cat >> /etc/security/limits.conf << EOF
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF

# 优化系统参数
print_info "优化系统参数..."
cat >> /etc/sysctl.conf << EOF
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.ip_local_port_range = 1024 65535
vm.swappiness = 10
EOF
sysctl -p

print_info "=========================================="
print_info "服务器环境初始化完成！"
print_info "=========================================="
print_info "Docker 版本: $(docker --version)"
print_info "Docker Compose 版本: $(docker-compose --version)"
