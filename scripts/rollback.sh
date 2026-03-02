#!/bin/bash
# 回滚脚本

set -e

echo "========================================="
echo "应用回滚工具"
echo "========================================="

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

BACKUP_DIR="/opt/backups"
APP_DIR="/opt/app"

# 列出可用的备份
echo "可用的备份："
echo "========================================="
ls -lht "$BACKUP_DIR"/app_backup_*.tar.gz | nl

# 选择备份
read -p "请输入要恢复的备份编号: " backup_num

# 获取选择的备份文件
backup_file=$(ls -t "$BACKUP_DIR"/app_backup_*.tar.gz | sed -n "${backup_num}p")

if [ -z "$backup_file" ]; then
    echo -e "${RED}无效的备份编号${NC}"
    exit 1
fi

echo -e "${GREEN}选择的备份: $backup_file${NC}"
read -p "确认回滚到此版本? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo "取消回滚"
    exit 0
fi

# 停止当前服务
echo "停止当前服务..."
cd "$APP_DIR"
docker-compose down

# 备份当前版本
echo "备份当前版本..."
tar -czf "$BACKUP_DIR/app_before_rollback_$(date +%Y%m%d_%H%M%S).tar.gz" -C "$APP_DIR" .

# 清空应用目录
echo "清空应用目录..."
rm -rf "$APP_DIR"/*

# 恢复备份
echo "恢复备份..."
tar -xzf "$backup_file" -C "$APP_DIR"

# 启动服务
echo "启动服务..."
cd "$APP_DIR"
docker-compose up -d

# 健康检查
echo "等待服务启动..."
sleep 10

if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}回滚成功！${NC}"
else
    echo -e "${RED}警告：健康检查失败，请检查日志${NC}"
fi
