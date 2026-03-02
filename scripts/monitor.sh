#!/bin/bash
# 应用监控脚本

echo "========================================="
echo "应用监控面板"
echo "========================================="

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Docker 容器状态
echo -e "${GREEN}Docker 容器状态:${NC}"
docker-compose ps
echo ""

# 2. 容器资源使用
echo -e "${GREEN}容器资源使用:${NC}"
docker stats --no-stream
echo ""

# 3. 健康检查
echo -e "${GREEN}健康检查:${NC}"
if curl -s http://localhost:8000/health | jq . 2>/dev/null; then
    echo -e "${GREEN}✓ 健康检查通过${NC}"
else
    echo -e "${RED}✗ 健康检查失败${NC}"
fi
echo ""

# 4. 最近日志
echo -e "${GREEN}最近应用日志 (最后 20 行):${NC}"
docker-compose logs --tail=20 app
echo ""

# 5. 数据库连接
echo -e "${GREEN}数据库状态:${NC}"
docker-compose exec -T db pg_isready -U postgres && echo -e "${GREEN}✓ 数据库正常${NC}" || echo -e "${RED}✗ 数据库异常${NC}"
echo ""

# 6. 磁盘使用
echo -e "${GREEN}磁盘使用:${NC}"
df -h | grep -E '^Filesystem|/$'
echo ""

# 7. 内存使用
echo -e "${GREEN}内存使用:${NC}"
free -h
echo ""

echo "========================================="
echo "监控完成"
echo "========================================="
