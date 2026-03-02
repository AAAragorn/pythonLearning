#!/bin/bash
set -e

echo "=========================================="
echo "Python 项目部署脚本"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 配置变量
APP_DIR="/opt/app"
DOCKER_COMPOSE_FILE="docker-compose.yml"
BACKUP_DIR="/opt/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 函数：打印信息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 函数：检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 未安装，请先安装"
        exit 1
    fi
}

# 函数：备份
backup() {
    print_info "开始备份..."
    mkdir -p $BACKUP_DIR
    
    if [ -d "$APP_DIR" ]; then
        tar -czf "$BACKUP_DIR/app_backup_$TIMESTAMP.tar.gz" -C $(dirname $APP_DIR) $(basename $APP_DIR)
        print_info "备份完成: $BACKUP_DIR/app_backup_$TIMESTAMP.tar.gz"
    else
        print_warning "应用目录不存在，跳过备份"
    fi
}

# 函数：部署
deploy() {
    print_info "开始部署..."
    
    # 进入应用目录
    cd $APP_DIR
    
    # 拉取最新镜像
    print_info "拉取最新 Docker 镜像..."
    docker-compose -f $DOCKER_COMPOSE_FILE pull
    
    # 停止旧容器
    print_info "停止旧容器..."
    docker-compose -f $DOCKER_COMPOSE_FILE down
    
    # 启动新容器
    print_info "启动新容器..."
    docker-compose -f $DOCKER_COMPOSE_FILE up -d
    
    # 清理未使用的镜像
    print_info "清理未使用的 Docker 资源..."
    docker system prune -f
}

# 函数：健康检查
health_check() {
    print_info "执行健康检查..."
    
    MAX_RETRIES=10
    RETRY_INTERVAL=3
    
    for i in $(seq 1 $MAX_RETRIES); do
        if curl -f http://localhost:5000/health &> /dev/null; then
            print_info "应用健康检查通过"
            return 0
        fi
        
        print_warning "健康检查失败，重试 $i/$MAX_RETRIES..."
        sleep $RETRY_INTERVAL
    done
    
    print_error "应用健康检查失败"
    return 1
}

# 函数：回滚
rollback() {
    print_warning "开始回滚..."
    
    # 找到最新的备份
    LATEST_BACKUP=$(ls -t $BACKUP_DIR/app_backup_*.tar.gz 2>/dev/null | head -1)
    
    if [ -z "$LATEST_BACKUP" ]; then
        print_error "未找到备份文件，无法回滚"
        exit 1
    fi
    
    print_info "使用备份: $LATEST_BACKUP"
    
    # 停止当前容器
    cd $APP_DIR
    docker-compose -f $DOCKER_COMPOSE_FILE down
    
    # 恢复备份
    rm -rf $APP_DIR
    tar -xzf $LATEST_BACKUP -C $(dirname $APP_DIR)
    
    # 重新启动
    cd $APP_DIR
    docker-compose -f $DOCKER_COMPOSE_FILE up -d
    
    print_info "回滚完成"
}

# 主函数
main() {
    # 检查必要命令
    check_command docker
    check_command docker-compose
    check_command curl
    
    case "${1:-deploy}" in
        deploy)
            backup
            deploy
            if ! health_check; then
                print_error "部署失败，开始回滚"
                rollback
                exit 1
            fi
            print_info "部署成功！"
            ;;
        rollback)
            rollback
            ;;
        backup)
            backup
            ;;
        health)
            health_check
            ;;
        *)
            echo "用法: $0 {deploy|rollback|backup|health}"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
