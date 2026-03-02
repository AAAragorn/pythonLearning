# Python 项目完整部署教程

本教程详细介绍如何部署一个 Python Web 应用，涵盖从环境准备到 CI/CD 流程的完整过程。

## 目录

1. [环境准备](#1-环境准备)
2. [项目结构](#2-项目结构)
3. [依赖管理](#3-依赖管理)
4. [部署到服务器](#4-部署到服务器)
5. [Docker 部署](#5-docker-部署)
6. [CI/CD 流程](#6-cicd-流程)

---

## 1. 环境准备

### 1.1 本地开发环境

#### 必需软件

- **Python 3.9+**
  ```bash
  # macOS
  brew install python@3.11
  
  # Ubuntu/Debian
  sudo apt-get update
  sudo apt-get install python3.11 python3.11-venv python3-pip
  
  # Windows
  # 从 https://www.python.org/downloads/ 下载安装
  ```

- **Git**
  ```bash
  # macOS
  brew install git
  
  # Ubuntu/Debian
  sudo apt-get install git
  ```

- **Docker & Docker Compose** (可选，用于容器化开发)
  ```bash
  # macOS
  brew install docker docker-compose
  
  # Ubuntu/Debian - 使用官方安装脚本
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo usermod -aG docker $USER
  ```

#### 创建虚拟环境

```bash
# 创建虚拟环境
python3 -m venv venv

# 激活虚拟环境
# Linux/macOS
source venv/bin/activate

# Windows
venv\Scripts\activate
```

#### 安装开发依赖

```bash
pip install --upgrade pip
pip install -r requirements-dev.txt
```

### 1.2 生产服务器环境

#### 服务器要求

- **操作系统**: Ubuntu 20.04 LTS 或更高版本
- **最低配置**: 
  - CPU: 2核
  - 内存: 4GB
  - 磁盘: 20GB
- **网络**: 公网 IP 地址，开放 80/443 端口

#### 一键初始化服务器

```bash
# 以 root 用户登录服务器后执行
chmod +x scripts/setup-server.sh
sudo ./scripts/setup-server.sh
```

这个脚本将自动：
- 更新系统包
- 安装 Docker 和 Docker Compose
- 配置防火墙 (UFW)
- 安装 fail2ban 防护
- 创建部署用户
- 优化系统参数

---

## 2. 项目结构

```
project/
├── app/                        # 应用主目录
│   ├── __init__.py            # 应用工厂
│   ├── config.py              # 配置管理
│   └── routes.py              # 路由定义
├── tests/                      # 测试目录
│   ├── __init__.py
│   └── test_app.py            # 单元测试
├── scripts/                    # 部署脚本
│   ├── deploy.sh              # 部署脚本
│   ├── setup-server.sh        # 服务器初始化脚本
│   ├── local-dev.sh           # 本地开发脚本
│   └── test.sh                # 测试脚本
├── nginx/                      # Nginx 配置
│   └── nginx.conf             # Nginx 配置文件
├── .github/                    # GitHub Actions
│   └── workflows/
│       ├── ci.yml             # 持续集成
│       ├── cd.yml             # 持续部署
│       └── docker-build.yml   # Docker 构建测试
├── Dockerfile                  # 生产环境 Dockerfile
├── Dockerfile.dev              # 开发环境 Dockerfile
├── docker-compose.yml          # Docker Compose 配置
├── docker-compose.dev.yml      # 开发环境 Compose 配置
├── requirements.txt            # 生产依赖
├── requirements-dev.txt        # 开发依赖
├── setup.py                    # 包安装配置
├── run.py                      # 开发服务器入口
├── wsgi.py                     # WSGI 入口（生产环境）
├── Makefile                    # 常用命令快捷方式
├── .env.example                # 环境变量示例
├── .gitignore                  # Git 忽略文件
└── README.md                   # 项目说明
```

### 核心文件说明

#### `app/__init__.py` - 应用工厂模式

应用工厂模式便于测试和配置管理：

```python
from flask import Flask
from .config import Config

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)
    return app
```

#### `app/config.py` - 配置管理

支持多环境配置（开发、测试、生产）：

```python
class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY')
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL')
```

#### `wsgi.py` - 生产环境入口

WSGI 服务器（如 Gunicorn）的入口文件。

---

## 3. 依赖管理

### 3.1 requirements.txt 结构

**requirements.txt** - 生产环境依赖：
```
Flask==3.0.0
python-dotenv==1.0.0
gunicorn==21.2.0
redis==5.0.1
pytest==7.4.3
pytest-cov==4.1.0
```

**requirements-dev.txt** - 开发环境依赖：
```
-r requirements.txt

black==23.12.1
flake8==7.0.0
mypy==1.8.0
pylint==3.0.3
```

### 3.2 依赖版本管理

#### 固定版本 vs 范围版本

```bash
# 固定版本（推荐生产环境）
Flask==3.0.0

# 范围版本（开发环境）
Flask>=3.0.0,<4.0.0

# 最新兼容版本
Flask~=3.0.0  # 等同于 >=3.0.0,<3.1.0
```

#### 生成依赖文件

```bash
# 导出当前环境所有依赖
pip freeze > requirements.txt

# 只导出直接依赖（推荐）
pip install pipreqs
pipreqs . --force
```

### 3.3 使用 setup.py

`setup.py` 使项目可以作为包安装：

```bash
# 开发模式安装（可编辑）
pip install -e .

# 安装额外依赖
pip install -e .[dev]

# 构建发行包
python setup.py sdist bdist_wheel
```

### 3.4 依赖安全检查

```bash
# 使用 safety 检查已知漏洞
pip install safety
safety check

# 使用 pip-audit
pip install pip-audit
pip-audit
```

---

## 4. 部署到服务器

### 4.1 传统方式部署

#### 步骤 1: 连接服务器

```bash
ssh deploy@your-server-ip
```

#### 步骤 2: 克隆代码

```bash
cd /opt
sudo git clone https://github.com/yourusername/your-repo.git app
sudo chown -R deploy:deploy /opt/app
cd /opt/app
```

#### 步骤 3: 配置环境

```bash
# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 配置环境变量
cp .env.example .env
vim .env  # 编辑配置
```

#### 步骤 4: 使用 Gunicorn + Nginx

**安装 Gunicorn**
```bash
pip install gunicorn
```

**创建 Systemd 服务文件**

创建 `/etc/systemd/system/myapp.service`:

```ini
[Unit]
Description=Gunicorn instance to serve myapp
After=network.target

[Service]
User=deploy
Group=deploy
WorkingDirectory=/opt/app
Environment="PATH=/opt/app/venv/bin"
ExecStart=/opt/app/venv/bin/gunicorn --workers 4 --bind 0.0.0.0:5000 wsgi:app

[Install]
WantedBy=multi-user.target
```

**启动服务**
```bash
sudo systemctl daemon-reload
sudo systemctl start myapp
sudo systemctl enable myapp
sudo systemctl status myapp
```

**配置 Nginx**

安装 Nginx:
```bash
sudo apt-get install nginx
```

创建配置文件 `/etc/nginx/sites-available/myapp`:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

启用站点:
```bash
sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

#### 步骤 5: 配置 SSL (Let's Encrypt)

```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
sudo systemctl reload nginx
```

### 4.2 使用部署脚本

```bash
# 自动化部署
chmod +x scripts/deploy.sh
./scripts/deploy.sh deploy

# 健康检查
./scripts/deploy.sh health

# 回滚
./scripts/deploy.sh rollback
```

---

## 5. Docker 部署

### 5.1 Dockerfile 详解

#### 多阶段构建优化

```dockerfile
# 阶段 1: 构建依赖
FROM python:3.11-slim as builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# 阶段 2: 运行时
FROM python:3.11-slim

WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .

ENV PATH=/root/.local/bin:$PATH
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "wsgi:app"]
```

### 5.2 Docker Compose 部署

#### 启动服务

```bash
# 构建并启动
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

#### 环境配置

创建 `.env` 文件：

```bash
SECRET_KEY=your-secret-key
DATABASE_URL=postgresql://user:pass@db:5432/dbname
REDIS_URL=redis://redis:6379/0
```

### 5.3 生产环境最佳实践

#### 使用非 root 用户

```dockerfile
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app
USER appuser
```

#### 健康检查

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost:5000/health || exit 1
```

#### 资源限制

```yaml
services:
  web:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

### 5.4 Docker 常用命令

```bash
# 查看运行中的容器
docker ps

# 进入容器
docker exec -it python-app bash

# 查看容器日志
docker logs -f python-app

# 重启容器
docker restart python-app

# 清理未使用的资源
docker system prune -af
```

---

## 6. CI/CD 流程

### 6.1 GitHub Actions 配置

项目包含三个工作流：

1. **ci.yml** - 持续集成（代码检查、测试）
2. **cd.yml** - 持续部署（构建镜像、部署）
3. **docker-build.yml** - Docker 构建测试

### 6.2 CI 工作流详解

#### 代码质量检查

```yaml
- name: Lint with flake8
  run: |
    flake8 app tests --max-line-length=127

- name: Format check with black
  run: |
    black --check app tests
```

#### 自动化测试

```yaml
- name: Run tests with pytest
  run: |
    pytest tests/ -v --cov=app --cov-report=xml
```

#### 多版本测试

```yaml
strategy:
  matrix:
    python-version: ['3.9', '3.10', '3.11', '3.12']
```

### 6.3 CD 工作流详解

#### 构建并推送 Docker 镜像

```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    push: true
    tags: ${{ steps.meta.outputs.tags }}
    cache-from: type=registry,ref=...
```

#### 自动部署到服务器

```yaml
- name: Deploy to server via SSH
  uses: appleboy/ssh-action@v1.0.0
  with:
    host: ${{ secrets.DEPLOY_HOST }}
    username: ${{ secrets.DEPLOY_USER }}
    key: ${{ secrets.DEPLOY_KEY }}
    script: |
      cd /opt/app
      docker-compose pull
      docker-compose up -d
```

### 6.4 配置 Secrets

在 GitHub 仓库设置中添加以下 Secrets：

| Secret 名称 | 描述 | 示例值 |
|------------|------|--------|
| `DEPLOY_HOST` | 服务器 IP 地址 | `192.168.1.100` |
| `DEPLOY_USER` | SSH 用户名 | `deploy` |
| `DEPLOY_KEY` | SSH 私钥 | `-----BEGIN RSA PRIVATE KEY-----...` |
| `DEPLOY_PORT` | SSH 端口 | `22` |
| `APP_URL` | 应用 URL | `https://api.example.com` |

#### 生成 SSH 密钥

```bash
# 在本地生成 SSH 密钥对
ssh-keygen -t rsa -b 4096 -C "deploy@example.com" -f deploy_key

# 将公钥添加到服务器
ssh-copy-id -i deploy_key.pub deploy@your-server

# 将私钥内容添加到 GitHub Secrets (DEPLOY_KEY)
cat deploy_key
```

### 6.5 GitLab CI/CD 配置

如果使用 GitLab，创建 `.gitlab-ci.yml`:

```yaml
stages:
  - test
  - build
  - deploy

test:
  stage: test
  image: python:3.11
  script:
    - pip install -r requirements-dev.txt
    - pytest tests/ -v --cov=app
  coverage: '/TOTAL.*\s+(\d+%)$/'

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

deploy:
  stage: deploy
  only:
    - main
  script:
    - ssh deploy@$DEPLOY_HOST "cd /opt/app && docker-compose pull && docker-compose up -d"
```

### 6.6 监控和告警

#### 集成健康检查

```python
@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    }), 200
```

#### 配置告警

使用 GitHub Actions 发送通知：

```yaml
- name: Notify on failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 7. 快速开始命令

### 本地开发

```bash
# 使用 Makefile
make install-dev     # 安装依赖
make test            # 运行测试
make run             # 启动开发服务器

# 使用脚本
./scripts/local-dev.sh
```

### Docker 开发

```bash
# 启动开发环境
docker-compose -f docker-compose.dev.yml up

# 访问应用
curl http://localhost:5000
```

### 生产部署

```bash
# 使用 Docker Compose
docker-compose up -d

# 使用部署脚本
./scripts/deploy.sh deploy

# 检查状态
./scripts/deploy.sh health
```

---

## 8. 故障排查

### 常见问题

#### 1. 端口被占用

```bash
# 查找占用端口的进程
sudo lsof -i :5000
# 或
sudo netstat -tulpn | grep 5000

# 杀死进程
sudo kill -9 <PID>
```

#### 2. Docker 容器无法启动

```bash
# 查看容器日志
docker logs python-app

# 查看详细信息
docker inspect python-app

# 进入容器调试
docker exec -it python-app /bin/bash
```

#### 3. 数据库连接失败

```bash
# 检查数据库容器状态
docker ps | grep postgres

# 测试数据库连接
docker exec -it postgres-db psql -U postgres -d appdb
```

#### 4. Nginx 配置错误

```bash
# 测试配置
sudo nginx -t

# 查看错误日志
sudo tail -f /var/log/nginx/error.log
```

---

## 9. 性能优化

### 应用层优化

1. **使用缓存**
   ```python
   from flask_caching import Cache
   cache = Cache(app, config={'CACHE_TYPE': 'redis'})
   ```

2. **数据库查询优化**
   - 使用索引
   - 避免 N+1 查询
   - 使用查询缓存

3. **异步任务队列**
   ```bash
   pip install celery
   ```

### Docker 优化

1. **减小镜像体积**
   - 使用 alpine 基础镜像
   - 多阶段构建
   - 清理缓存

2. **使用 Docker BuildKit**
   ```bash
   DOCKER_BUILDKIT=1 docker build -t myapp .
   ```

### Nginx 优化

```nginx
# 启用 gzip 压缩
gzip on;
gzip_types text/plain application/json;

# 启用缓存
location /static {
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```

---

## 10. 安全最佳实践

### 应用安全

1. **环境变量管理**
   - 永远不要提交 `.env` 文件
   - 使用强密钥
   - 定期轮换密钥

2. **依赖安全**
   ```bash
   # 定期检查漏洞
   safety check
   pip-audit
   ```

3. **输入验证**
   ```python
   from flask import request
   from werkzeug.security import escape
   
   data = escape(request.form.get('input'))
   ```

### 服务器安全

1. **SSH 配置**
   ```bash
   # 禁用密码登录
   sudo vim /etc/ssh/sshd_config
   # PasswordAuthentication no
   ```

2. **防火墙配置**
   ```bash
   sudo ufw enable
   sudo ufw allow 22
   sudo ufw allow 80
   sudo ufw allow 443
   ```

3. **自动更新**
   ```bash
   sudo apt-get install unattended-upgrades
   sudo dpkg-reconfigure -plow unattended-upgrades
   ```

---

## 11. 监控和日志

### 应用监控

#### 使用 Prometheus + Grafana

```bash
# docker-compose.yml 添加
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
  
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
```

### 日志管理

#### 集中式日志收集

```python
import logging
from logging.handlers import RotatingFileHandler

handler = RotatingFileHandler(
    'logs/app.log',
    maxBytes=10000000,
    backupCount=10
)
app.logger.addHandler(handler)
```

---

## 12. 总结

本教程涵盖了 Python 项目部署的完整流程：

✅ **环境准备**: 本地开发和生产服务器配置  
✅ **项目结构**: 清晰的目录组织  
✅ **依赖管理**: requirements.txt 和 setup.py  
✅ **传统部署**: Gunicorn + Nginx + Systemd  
✅ **容器化部署**: Docker + Docker Compose  
✅ **自动化部署**: GitHub Actions CI/CD  
✅ **监控运维**: 日志、监控、告警  
✅ **安全加固**: 应用和服务器安全  

### 下一步

- 配置监控和告警系统
- 实施自动化备份策略
- 优化应用性能
- 建立完善的文档

### 相关资源

- [Flask 官方文档](https://flask.palletsprojects.com/)
- [Docker 官方文档](https://docs.docker.com/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Nginx 官方文档](https://nginx.org/en/docs/)

---

**如有问题，请查看故障排查章节或提交 Issue。**
