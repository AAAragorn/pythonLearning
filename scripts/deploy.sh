#!/bin/bash
# 部署脚本

set -e

echo "========================================="
echo "开始部署 Python 应用"
echo "========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
APP_DIR="/opt/app"
BACKUP_DIR="/opt/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 函数：打印信息
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 检查是否为 root 用户
if [[ $EUID -ne 0 ]]; then
   warn "建议使用 root 用户运行此脚本"
fi

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 1. 备份当前版本
info "备份当前版本..."
if [ -d "$APP_DIR" ]; then
    tar -czf "$BACKUP_DIR/app_backup_$TIMESTAMP.tar.gz" -C "$APP_DIR" . || warn "备份失败，继续部署"
fi

# 2. 拉取最新代码
info "拉取最新代码..."
cd "$APP_DIR" || error "应用目录不存在"
git pull origin main || error "代码拉取失败"

# 3. 拉取最新 Docker 镜像
info "拉取最新 Docker 镜像..."
docker-compose pull || error "镜像拉取失败"

# 4. 停止旧容器
info "停止旧容器..."
docker-compose down || warn "停止容器失败"

# 5. 启动新容器
info "启动新容器..."
docker-compose up -d || error "启动容器失败"

# 6. 等待服务启动
info "等待服务启动..."
sleep 10

# 7. 运行数据库迁移
info "运行数据库迁移..."
docker-compose exec -T app python -c "from app.database import init_db; init_db()" || warn "数据库迁移失败"

# 8. 健康检查
info "执行健康检查..."
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        info "健康检查通过！"
        break
    fi
    attempt=$((attempt + 1))
    echo "等待服务就绪... ($attempt/$max_attempts)"
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    error "健康检查失败，部署可能存在问题"
fi

# 9. 清理旧镜像
info "清理旧 Docker 镜像..."
docker image prune -f || warn "清理镜像失败"

# 10. 清理旧备份（保留最近 5 个）
info "清理旧备份..."
cd "$BACKUP_DIR"
ls -t app_backup_*.tar.gz | tail -n +6 | xargs -r rm -f

echo "========================================="
echo -e "${GREEN}部署完成！${NC}"
echo "========================================="
echo "应用地址: http://localhost:8000"
echo "API 文档: http://localhost:8000/docs"
echo "健康检查: http://localhost:8000/health"
echo "========================================="
