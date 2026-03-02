# Python 项目部署完整教程

[![CI/CD](https://github.com/yourusername/python-deployment/workflows/CI/CD%20Pipeline/badge.svg)](https://github.com/yourusername/python-deployment/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

这是一个完整的 Python 项目部署教程，涵盖从开发到生产环境的全流程，包括环境准备、项目结构、依赖管理、服务器部署、Docker 容器化以及 CI/CD 自动化流程。

## 📋 目录

- [1. 环境准备](#1-环境准备)
- [2. 项目结构](#2-项目结构)
- [3. 依赖管理](#3-依赖管理)
- [4. 本地开发](#4-本地开发)
- [5. Docker 部署](#5-docker-部署)
- [6. 服务器部署](#6-服务器部署)
- [7. CI/CD 流程](#7-cicd-流程)
- [8. 监控与维护](#8-监控与维护)
- [9. 常见问题](#9-常见问题)

---

## 1. 环境准备

### 1.1 本地开发环境

#### 必需软件

```bash
# Python 3.11+
python --version

# Git
git --version

# Docker & Docker Compose
docker --version
docker compose version
```

#### 安装 Python (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y python3.11 python3.11-venv python3-pip
```

#### 安装 Python (macOS)

```bash
brew install python@3.11
```

#### 安装 Docker

**Ubuntu/Debian:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

**macOS:**
```bash
brew install --cask docker
```

### 1.2 生产服务器环境

运行服务器初始化脚本：

```bash
# 需要 root 权限
sudo bash scripts/setup.sh
```

该脚本会自动安装：
- Docker 和 Docker Compose
- 配置防火墙
- 创建应用用户和目录
- 优化系统参数

---

## 2. 项目结构

```
python-deployment/
├── app/                          # 应用代码
│   ├── __init__.py
│   ├── main.py                   # FastAPI 主应用
│   ├── config.py                 # 配置管理
│   └── database.py               # 数据库操作
├── tests/                        # 测试代码
│   ├── __init__.py
│   └── test_main.py
├── scripts/                      # 部署脚本
│   ├── setup.sh                  # 环境初始化
│   ├── deploy.sh                 # 部署脚本
│   ├── rollback.sh               # 回滚脚本
│   └── monitor.sh                # 监控脚本
├── deployment/                   # 部署配置
│   └── init.sql                  # 数据库初始化
├── nginx/                        # Nginx 配置
│   ├── nginx.conf
│   └── conf.d/
│       └── app.conf
├── .github/                      # GitHub Actions CI/CD
│   └── workflows/
│       ├── ci.yml
│       └── docker-publish.yml
├── Dockerfile                    # 生产环境镜像
├── Dockerfile.dev                # 开发环境镜像
├── docker-compose.yml            # 生产环境编排
├── docker-compose.dev.yml        # 开发环境编排
├── requirements.txt              # Python 依赖
├── requirements-dev.txt          # 开发依赖
├── pyproject.toml                # Poetry 配置
├── .env.example                  # 环境变量示例
├── .dockerignore                 # Docker 忽略文件
├── .gitignore                    # Git 忽略文件
└── README.md                     # 项目文档
```

### 核心文件说明

| 文件 | 说明 |
|------|------|
| `app/main.py` | FastAPI 应用入口，定义 API 路由 |
| `app/config.py` | 应用配置，使用 pydantic-settings |
| `Dockerfile` | 多阶段构建的生产环境镜像 |
| `docker-compose.yml` | 包含应用、数据库、Nginx 的完整栈 |
| `.github/workflows/ci.yml` | CI/CD 自动化流程 |

---

## 3. 依赖管理

### 3.1 使用 pip + requirements.txt

**安装依赖：**

```bash
# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/macOS
# 或 venv\Scripts\activate  # Windows

# 安装依赖
pip install -r requirements.txt

# 开发环境
pip install -r requirements-dev.txt
```

**添加新依赖：**

```bash
pip install package-name
pip freeze > requirements.txt
```

### 3.2 使用 Poetry (推荐)

**安装 Poetry：**

```bash
curl -sSL https://install.python-poetry.org | python3 -
```

**使用 Poetry：**

```bash
# 安装依赖
poetry install

# 添加新依赖
poetry add fastapi

# 添加开发依赖
poetry add --group dev pytest

# 激活虚拟环境
poetry shell

# 运行命令
poetry run python app/main.py
```

### 3.3 依赖说明

**核心依赖：**
- `fastapi` - 现代高性能 Web 框架
- `uvicorn` - ASGI 服务器
- `pydantic` - 数据验证
- `databases` - 异步数据库支持
- `sqlalchemy` - SQL 工具包
- `asyncpg` - PostgreSQL 异步驱动

**开发依赖：**
- `pytest` - 测试框架
- `black` - 代码格式化
- `flake8` - 代码检查
- `mypy` - 类型检查

---

## 4. 本地开发

### 4.1 配置环境变量

```bash
# 复制环境变量示例文件
cp .env.example .env

# 编辑 .env 文件
vim .env
```

示例 `.env` 文件：

```env
APP_NAME=Python部署示例
VERSION=1.0.0
DEBUG=True

DATABASE_URL=postgresql://postgres:postgres@localhost:5432/appdb
SECRET_KEY=your-secret-key-for-development
LOG_LEVEL=DEBUG
```

### 4.2 启动开发环境 (使用 Docker Compose)

```bash
# 启动所有服务
docker compose -f docker-compose.dev.yml up

# 后台运行
docker compose -f docker-compose.dev.yml up -d

# 查看日志
docker compose -f docker-compose.dev.yml logs -f app

# 停止服务
docker compose -f docker-compose.dev.yml down
```

### 4.3 不使用 Docker 的本地开发

```bash
# 1. 启动 PostgreSQL (需要本地安装)
# 或使用 Docker 单独运行数据库
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=appdb \
  -p 5432:5432 \
  postgres:15-alpine

# 2. 激活虚拟环境
source venv/bin/activate

# 3. 运行应用
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 4.4 访问应用

- **应用首页**: http://localhost:8000
- **API 文档**: http://localhost:8000/docs
- **健康检查**: http://localhost:8000/health

### 4.5 运行测试

```bash
# 运行所有测试
pytest

# 带覆盖率报告
pytest --cov=app --cov-report=html

# 运行特定测试
pytest tests/test_main.py::test_health_check

# 查看覆盖率报告
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
```

### 4.6 代码质量检查

```bash
# 格式化代码
black app tests

# 排序导入
isort app tests

# 代码检查
flake8 app tests

# 类型检查
mypy app
```

---

## 5. Docker 部署

### 5.1 构建 Docker 镜像

```bash
# 构建生产镜像
docker build -t python-app:latest .

# 构建开发镜像
docker build -f Dockerfile.dev -t python-app:dev .

# 查看镜像
docker images | grep python-app
```

### 5.2 使用 Docker Compose 部署完整栈

**生产环境：**

```bash
# 启动所有服务 (应用 + 数据库 + Nginx + Redis)
docker compose up -d

# 查看运行状态
docker compose ps

# 查看日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f app

# 执行数据库初始化
docker compose exec app python -c "from app.database import init_db; init_db()"
```

**停止和清理：**

```bash
# 停止服务
docker compose down

# 停止并删除数据卷
docker compose down -v

# 重启特定服务
docker compose restart app
```

### 5.3 多阶段构建优化

我们的 Dockerfile 使用多阶段构建来减小镜像大小：

```dockerfile
# 阶段 1: 构建依赖
FROM python:3.11-slim as builder
# ... 安装依赖

# 阶段 2: 运行应用
FROM python:3.11-slim
# ... 只复制必要文件
```

**优势：**
- ✅ 镜像体积更小
- ✅ 构建速度更快 (利用缓存)
- ✅ 更安全 (不包含构建工具)

### 5.4 健康检查

Docker 容器包含健康检查：

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1
```

查看健康状态：

```bash
docker compose ps
# 或
docker inspect python-app | grep -A 10 Health
```

---

## 6. 服务器部署

### 6.1 服务器要求

**最低配置：**
- CPU: 2 核心
- 内存: 4GB RAM
- 存储: 20GB SSD
- 系统: Ubuntu 20.04+ / Debian 11+

**推荐配置：**
- CPU: 4+ 核心
- 内存: 8GB+ RAM
- 存储: 50GB+ SSD

### 6.2 初始化服务器

```bash
# 1. SSH 登录服务器
ssh root@your-server-ip

# 2. 运行初始化脚本
bash <(curl -s https://raw.githubusercontent.com/yourusername/python-deployment/main/scripts/setup.sh)

# 或者手动上传并执行
scp scripts/setup.sh root@your-server-ip:/tmp/
ssh root@your-server-ip 'bash /tmp/setup.sh'
```

### 6.3 部署应用

**方式一：使用部署脚本 (推荐)**

```bash
# 1. 克隆代码
cd /opt
git clone https://github.com/yourusername/python-deployment.git app
cd app

# 2. 配置环境变量
cp .env.example .env
vim .env  # 修改为生产配置

# 3. 运行部署脚本
bash scripts/deploy.sh
```

**方式二：手动部署**

```bash
cd /opt/app

# 1. 拉取最新代码
git pull origin main

# 2. 拉取镜像
docker compose pull

# 3. 启动服务
docker compose up -d

# 4. 初始化数据库
docker compose exec -T app python -c "from app.database import init_db; init_db()"

# 5. 健康检查
curl http://localhost:8000/health
```

### 6.4 配置域名和 SSL

**1. 配置 DNS：**

将域名 A 记录指向服务器 IP

**2. 获取 SSL 证书 (使用 Let's Encrypt)：**

```bash
# 安装 Certbot
sudo apt install certbot

# 获取证书
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# 证书位置
# /etc/letsencrypt/live/yourdomain.com/fullchain.pem
# /etc/letsencrypt/live/yourdomain.com/privkey.pem
```

**3. 更新 Nginx 配置：**

编辑 `nginx/conf.d/app.conf`，修改：

```nginx
server_name yourdomain.com www.yourdomain.com;
ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
```

**4. 重启 Nginx：**

```bash
docker compose restart nginx
```

### 6.5 配置防火墙

```bash
# 允许 HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp

# 启用防火墙
sudo ufw enable

# 查看状态
sudo ufw status
```

---

## 7. CI/CD 流程

### 7.1 GitHub Actions 配置

我们的 CI/CD 流程包含：

1. **代码质量检查** - Black, Flake8, isort, MyPy
2. **自动化测试** - pytest + 覆盖率报告
3. **Docker 镜像构建** - 多平台构建
4. **自动部署** - SSH 到服务器部署

### 7.2 配置 GitHub Secrets

在 GitHub 仓库设置中添加以下 Secrets：

| Secret 名称 | 说明 |
|------------|------|
| `DOCKER_USERNAME` | Docker Hub 用户名 |
| `DOCKER_PASSWORD` | Docker Hub 密码/Token |
| `SERVER_HOST` | 服务器 IP 或域名 |
| `SERVER_USER` | 服务器用户名 |
| `SSH_PRIVATE_KEY` | SSH 私钥 |

**生成 SSH 密钥：**

```bash
# 在本地生成密钥对
ssh-keygen -t ed25519 -C "github-actions"

# 将公钥添加到服务器
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server

# 复制私钥内容到 GitHub Secrets
cat ~/.ssh/id_ed25519
```

### 7.3 工作流程

**推送到 main 分支时：**

```
┌─────────────┐
│  git push   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 代码检查     │ (Black, Flake8, MyPy)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 运行测试     │ (pytest + coverage)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 构建镜像     │ (Docker build & push)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 自动部署     │ (SSH to server)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 健康检查     │
└─────────────┘
```

### 7.4 GitLab CI/CD

如果使用 GitLab，配置 `.gitlab-ci.yml` 中的变量：

**Settings > CI/CD > Variables:**

- `DOCKER_REGISTRY_USER`
- `DOCKER_REGISTRY_PASSWORD`
- `SSH_PRIVATE_KEY`
- `SERVER_HOST`
- `SERVER_USER`

### 7.5 手动触发部署

**GitHub Actions:**

在 Actions 页面，选择 workflow 并点击 "Run workflow"

**使用 webhook:**

```bash
curl -X POST \
  -H "Authorization: token YOUR_GITHUB_TOKEN" \
  https://api.github.com/repos/USERNAME/REPO/dispatches \
  -d '{"event_type":"deploy"}'
```

---

## 8. 监控与维护

### 8.1 查看应用状态

```bash
# 使用监控脚本
bash scripts/monitor.sh

# 或手动检查
docker compose ps
docker compose logs -f app
curl http://localhost:8000/health
```

### 8.2 日志管理

**查看实时日志：**

```bash
# 所有服务
docker compose logs -f

# 特定服务
docker compose logs -f app
docker compose logs -f nginx
docker compose logs -f db

# 最近 100 行
docker compose logs --tail=100 app
```

**日志持久化：**

日志会保存在 `./logs` 目录中，并通过 logrotate 自动轮转。

### 8.3 数据库备份

**手动备份：**

```bash
# 备份数据库
docker compose exec db pg_dump -U postgres appdb > backup_$(date +%Y%m%d).sql

# 恢复数据库
docker compose exec -T db psql -U postgres appdb < backup_20240101.sql
```

**自动备份脚本：**

```bash
# 创建备份脚本
cat > /opt/scripts/backup_db.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/backups/database"
mkdir -p $BACKUP_DIR
cd /opt/app
docker compose exec -T db pg_dump -U postgres appdb | gzip > $BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql.gz
# 保留最近 7 天的备份
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +7 -delete
EOF

chmod +x /opt/scripts/backup_db.sh

# 添加到 crontab
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/scripts/backup_db.sh") | crontab -
```

### 8.4 回滚版本

```bash
# 使用回滚脚本
bash scripts/rollback.sh

# 或手动回滚
cd /opt/app
git log --oneline -10  # 查看提交历史
git reset --hard COMMIT_HASH
docker compose down
docker compose up -d
```

### 8.5 性能监控

**安装监控工具：**

```bash
# Prometheus + Grafana (可选)
docker run -d \
  --name prometheus \
  -p 9090:9090 \
  prom/prometheus

docker run -d \
  --name grafana \
  -p 3000:3000 \
  grafana/grafana
```

**监控指标：**
- CPU 使用率
- 内存使用率
- 请求响应时间
- 错误率
- 数据库连接数

---

## 9. 常见问题

### 9.1 容器启动失败

**问题：** 容器反复重启

**解决：**
```bash
# 查看容器日志
docker compose logs app

# 检查配置
docker compose config

# 检查端口占用
sudo lsof -i :8000
```

### 9.2 数据库连接失败

**问题：** `could not connect to server`

**解决：**
```bash
# 检查数据库状态
docker compose ps db

# 检查数据库日志
docker compose logs db

# 确认 DATABASE_URL 配置正确
docker compose exec app env | grep DATABASE_URL

# 测试连接
docker compose exec db psql -U postgres -c "SELECT 1"
```

### 9.3 Nginx 502 错误

**问题：** Nginx 返回 502 Bad Gateway

**解决：**
```bash
# 检查应用是否运行
docker compose ps app

# 检查应用健康状态
curl http://localhost:8000/health

# 检查 Nginx 配置
docker compose exec nginx nginx -t

# 查看 Nginx 日志
docker compose logs nginx
```

### 9.4 内存不足

**问题：** 服务器内存耗尽

**解决：**
```bash
# 查看内存使用
free -h
docker stats

# 限制容器内存
# 在 docker-compose.yml 中添加：
services:
  app:
    mem_limit: 512m
    memswap_limit: 512m

# 清理未使用的资源
docker system prune -a
```

### 9.5 磁盘空间不足

**问题：** No space left on device

**解决：**
```bash
# 查看磁盘使用
df -h

# 清理 Docker 资源
docker system prune -a --volumes

# 清理旧日志
sudo journalctl --vacuum-time=3d

# 清理旧备份
find /opt/backups -name "*.tar.gz" -mtime +30 -delete
```

### 9.6 SSL 证书过期

**问题：** HTTPS 证书过期

**解决：**
```bash
# 续期证书
sudo certbot renew

# 自动续期（添加到 crontab）
0 0 * * 0 certbot renew --quiet && docker compose restart nginx
```

---

## 10. 最佳实践

### 10.1 安全建议

✅ **使用强密码和密钥**
- 数据库密码至少 16 位
- 定期轮换 SECRET_KEY
- 使用 SSH 密钥代替密码

✅ **最小权限原则**
- 应用使用非 root 用户运行
- 数据库使用专用用户
- 限制容器网络访问

✅ **定期更新**
```bash
# 更新系统包
sudo apt update && sudo apt upgrade

# 更新 Docker 镜像
docker compose pull
docker compose up -d
```

### 10.2 性能优化

✅ **启用缓存**
```python
# 使用 Redis 缓存
import redis
cache = redis.Redis(host='redis', port=6379)
```

✅ **数据库连接池**
```python
# 在 config.py 中配置
DATABASE_POOL_SIZE = 20
DATABASE_MAX_OVERFLOW = 10
```

✅ **使用 CDN**
- 静态资源使用 CDN 加速
- 启用 Nginx gzip 压缩

### 10.3 备份策略

✅ **3-2-1 备份原则**
- 3 份副本
- 2 种不同媒介
- 1 份异地备份

✅ **定期测试恢复**
```bash
# 每月测试一次备份恢复
bash scripts/rollback.sh
```

---

## 11. 参考资源

### 文档

- [FastAPI 官方文档](https://fastapi.tiangolo.com/)
- [Docker 官方文档](https://docs.docker.com/)
- [PostgreSQL 文档](https://www.postgresql.org/docs/)
- [Nginx 文档](https://nginx.org/en/docs/)

### 工具

- [Poetry](https://python-poetry.org/) - Python 依赖管理
- [Pre-commit](https://pre-commit.com/) - Git hooks
- [GitHub Actions](https://github.com/features/actions) - CI/CD
- [Let's Encrypt](https://letsencrypt.org/) - 免费 SSL 证书

---

## 12. 贡献指南

欢迎提交 Issue 和 Pull Request！

**开发流程：**

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

---

## 13. 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 14. 联系方式

- **作者**: Your Name
- **邮箱**: your.email@example.com
- **GitHub**: https://github.com/yourusername

---

**⭐ 如果这个项目对你有帮助，请给一个 Star！**
