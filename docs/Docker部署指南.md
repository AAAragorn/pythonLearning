# Docker 部署详细指南

## 目录

1. [Docker 基础概念](#1-docker-基础概念)
2. [Dockerfile 详解](#2-dockerfile-详解)
3. [Docker Compose 编排](#3-docker-compose-编排)
4. [镜像优化](#4-镜像优化)
5. [生产环境部署](#5-生产环境部署)
6. [故障排查](#6-故障排查)

---

## 1. Docker 基础概念

### 1.1 核心概念

| 概念 | 说明 | 类比 |
|------|------|------|
| **镜像 (Image)** | 只读的应用模板 | 程序安装包 |
| **容器 (Container)** | 镜像的运行实例 | 运行中的程序 |
| **仓库 (Registry)** | 存储和分发镜像 | 应用商店 |
| **卷 (Volume)** | 持久化数据存储 | 外部硬盘 |
| **网络 (Network)** | 容器间通信 | 局域网 |

### 1.2 Docker vs 虚拟机

```
虚拟机架构                Docker 架构
┌──────────────┐         ┌──────────────┐
│  应用 A      │         │  应用 A      │
├──────────────┤         ├──────────────┤
│  Guest OS    │         │  容器运行时  │
├──────────────┤         ├──────────────┤
│  Hypervisor  │         │  Docker      │
├──────────────┤         ├──────────────┤
│  Host OS     │         │  Host OS     │
└──────────────┘         └──────────────┘
```

**Docker 优势**:
- 启动快（秒级）
- 资源占用少
- 部署简单
- 易于迁移

---

## 2. Dockerfile 详解

### 2.1 基础 Dockerfile

```dockerfile
# 选择基础镜像
FROM python:3.11-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# 复制依赖文件
COPY requirements.txt .

# 安装依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 5000

# 启动命令
CMD ["gunicorn", "-b", "0.0.0.0:5000", "wsgi:app"]
```

### 2.2 多阶段构建

**优势**: 减小最终镜像大小

```dockerfile
# ===== 阶段 1: 构建依赖 =====
FROM python:3.11-slim as builder

WORKDIR /app

# 安装编译依赖
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# 安装 Python 依赖到用户目录
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# ===== 阶段 2: 运行时环境 =====
FROM python:3.11-slim

WORKDIR /app

# 只复制必要的文件
COPY --from=builder /root/.local /root/.local
COPY . .

# 更新 PATH
ENV PATH=/root/.local/bin:$PATH

# 创建非 root 用户
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 5000

CMD ["gunicorn", "-b", "0.0.0.0:5000", "wsgi:app"]
```

**镜像大小对比**:
- 单阶段构建: ~800MB
- 多阶段构建: ~200MB

### 2.3 Dockerfile 指令详解

#### FROM - 基础镜像

```dockerfile
# 官方 Python 镜像
FROM python:3.11

# Alpine Linux（更小）
FROM python:3.11-alpine

# Slim 版本（推荐）
FROM python:3.11-slim

# 特定版本
FROM python:3.11.5-slim-bookworm
```

#### WORKDIR - 工作目录

```dockerfile
# 设置工作目录（会自动创建）
WORKDIR /app

# 后续的 RUN, CMD, COPY 都在此目录执行
COPY . .  # 复制到 /app
```

#### ENV - 环境变量

```dockerfile
# 单个变量
ENV APP_ENV=production

# 多个变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1
```

#### COPY vs ADD

```dockerfile
# COPY - 简单复制（推荐）
COPY requirements.txt .
COPY app/ app/

# ADD - 支持 URL 和自动解压（不推荐）
ADD https://example.com/file.tar.gz /tmp/
```

#### RUN - 执行命令

```dockerfile
# Shell 形式
RUN apt-get update

# Exec 形式（推荐）
RUN ["apt-get", "update"]

# 链式命令减少层数
RUN apt-get update && \
    apt-get install -y gcc && \
    rm -rf /var/lib/apt/lists/*
```

#### CMD vs ENTRYPOINT

```dockerfile
# CMD - 默认命令（可被覆盖）
CMD ["gunicorn", "wsgi:app"]
# 运行: docker run myapp          → gunicorn wsgi:app
# 运行: docker run myapp python   → python

# ENTRYPOINT - 入口点（不易被覆盖）
ENTRYPOINT ["gunicorn"]
CMD ["wsgi:app"]
# 运行: docker run myapp          → gunicorn wsgi:app
# 运行: docker run myapp -w 2     → gunicorn -w 2
```

#### HEALTHCHECK - 健康检查

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1
```

### 2.4 .dockerignore

**作用**: 排除不需要的文件，加快构建速度

```
# .dockerignore
__pycache__
*.pyc
*.pyo
.git
.gitignore
.env
.venv
venv/
tests/
*.md
!README.md
.DS_Store
.vscode/
```

---

## 3. Docker Compose 编排

### 3.1 基础配置

```yaml
version: '3.8'

services:
  web:
    build: .
    container_name: python-app
    ports:
      - "5000:5000"
    environment:
      - DATABASE_URL=postgresql://db:5432/app
    depends_on:
      - db
      - redis
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

volumes:
  postgres_data:
```

### 3.2 高级配置

#### 环境变量文件

```yaml
services:
  web:
    env_file:
      - .env
      - .env.production
```

#### 健康检查

```yaml
services:
  web:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

#### 资源限制

```yaml
services:
  web:
    deploy:
      resources:
        limits:
          cpus: '0.5'      # 最多使用 0.5 核
          memory: 512M     # 最多使用 512MB 内存
        reservations:
          cpus: '0.25'     # 保留 0.25 核
          memory: 256M     # 保留 256MB 内存
```

#### 日志配置

```yaml
services:
  web:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"    # 单个日志文件最大 10MB
        max-file: "3"      # 保留 3 个日志文件
```

#### 网络配置

```yaml
services:
  web:
    networks:
      - frontend
      - backend

  db:
    networks:
      - backend

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # 内部网络，不对外
```

### 3.3 开发与生产配置分离

**docker-compose.yml** (基础配置):

```yaml
version: '3.8'

services:
  web:
    build: .
    environment:
      - DATABASE_URL=${DATABASE_URL}
```

**docker-compose.override.yml** (开发环境自动加载):

```yaml
version: '3.8'

services:
  web:
    volumes:
      - .:/app
    ports:
      - "5000:5000"
    command: python run.py
```

**docker-compose.prod.yml** (生产环境):

```yaml
version: '3.8'

services:
  web:
    restart: always
    command: gunicorn -w 4 wsgi:app
```

**使用方式**:

```bash
# 开发环境（自动加载 override）
docker-compose up

# 生产环境
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## 4. 镜像优化

### 4.1 减小镜像体积

#### 使用 Alpine 基础镜像

```dockerfile
FROM python:3.11-alpine

# 安装运行时依赖
RUN apk add --no-cache \
    libpq \
    libffi

# 安装编译依赖（构建后删除）
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    musl-dev \
    postgresql-dev \
    && pip install --no-cache-dir -r requirements.txt \
    && apk del .build-deps
```

#### 清理缓存

```dockerfile
# APT 缓存
RUN apt-get update && apt-get install -y package \
    && rm -rf /var/lib/apt/lists/*

# pip 缓存
RUN pip install --no-cache-dir -r requirements.txt

# 临时文件
RUN some-command && rm -rf /tmp/*
```

#### 合并 RUN 指令

```dockerfile
# ❌ 不好 - 每个 RUN 创建一层
RUN apt-get update
RUN apt-get install -y gcc
RUN pip install -r requirements.txt

# ✅ 好 - 单个 RUN 减少层数
RUN apt-get update && \
    apt-get install -y gcc && \
    pip install -r requirements.txt && \
    apt-get purge -y gcc && \
    rm -rf /var/lib/apt/lists/*
```

### 4.2 利用构建缓存

```dockerfile
# ✅ 好 - 依赖变化少，先复制
COPY requirements.txt .
RUN pip install -r requirements.txt

# 代码变化频繁，后复制
COPY . .

# ❌ 不好 - 代码变化导致重新安装依赖
COPY . .
RUN pip install -r requirements.txt
```

### 4.3 使用 BuildKit

```bash
# 启用 BuildKit
export DOCKER_BUILDKIT=1

# 构建镜像
docker build -t myapp:latest .
```

**BuildKit 优势**:
- 并行构建
- 缓存挂载
- 秘密管理
- 更好的输出

```dockerfile
# 使用缓存挂载
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt
```

---

## 5. 生产环境部署

### 5.1 Docker Swarm 部署

#### 初始化 Swarm

```bash
# 管理节点
docker swarm init --advertise-addr <MANAGER-IP>

# 工作节点加入
docker swarm join --token <TOKEN> <MANAGER-IP>:2377
```

#### 部署服务

```bash
# 部署 Stack
docker stack deploy -c docker-compose.yml myapp

# 查看服务
docker service ls

# 扩容
docker service scale myapp_web=5

# 更新服务
docker service update --image myapp:v2 myapp_web
```

### 5.2 Kubernetes 部署

**deployment.yaml**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: python-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: python-app
  template:
    metadata:
      labels:
        app: python-app
    spec:
      containers:
      - name: web
        image: myapp:latest
        ports:
        - containerPort: 5000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: url
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: python-app-service
spec:
  selector:
    app: python-app
  ports:
  - port: 80
    targetPort: 5000
  type: LoadBalancer
```

### 5.3 监控和日志

#### 使用 Prometheus 监控

```yaml
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
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

#### 集中式日志

```yaml
services:
  web:
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: docker.web

  fluentd:
    image: fluent/fluentd
    ports:
      - "24224:24224"
```

---

## 6. 故障排查

### 6.1 常用调试命令

```bash
# 查看容器日志
docker logs -f <container-id>

# 进入运行中的容器
docker exec -it <container-id> bash

# 查看容器详细信息
docker inspect <container-id>

# 查看容器资源使用
docker stats <container-id>

# 查看容器进程
docker top <container-id>

# 复制文件到容器
docker cp file.txt <container-id>:/app/

# 从容器复制文件
docker cp <container-id>:/app/file.txt ./
```

### 6.2 常见问题

#### 问题 1: 容器立即退出

```bash
# 查看退出原因
docker logs <container-id>

# 查看退出码
docker inspect <container-id> | grep ExitCode
```

**常见退出码**:
- 0: 正常退出
- 1: 应用错误
- 137: 内存不足被杀死
- 139: 段错误

#### 问题 2: 无法连接到容器

```bash
# 检查端口映射
docker port <container-id>

# 检查网络
docker network inspect bridge

# 测试连接
docker exec <container-id> curl localhost:5000
```

#### 问题 3: 镜像构建失败

```bash
# 查看详细构建日志
docker build --no-cache --progress=plain -t myapp .

# 调试中间层
docker build --target builder -t debug .
docker run -it debug bash
```

#### 问题 4: 数据丢失

```bash
# 检查卷
docker volume ls

# 查看卷详情
docker volume inspect <volume-name>

# 备份卷
docker run --rm -v <volume>:/data -v $(pwd):/backup \
  alpine tar czf /backup/backup.tar.gz /data
```

### 6.3 性能优化

#### 限制日志大小

```yaml
services:
  web:
    logging:
      options:
        max-size: "10m"
        max-file: "3"
```

#### 使用内存限制

```bash
docker run -m 512m myapp
```

#### 清理无用资源

```bash
# 删除停止的容器
docker container prune

# 删除未使用的镜像
docker image prune -a

# 删除未使用的卷
docker volume prune

# 清理所有（危险！）
docker system prune -a --volumes
```

---

## 7. 最佳实践总结

### ✅ 推荐做法

1. **使用多阶段构建** - 减小镜像体积
2. **使用 .dockerignore** - 加快构建速度
3. **固定版本号** - 避免意外更新
4. **非 root 用户运行** - 提高安全性
5. **健康检查** - 自动重启故障容器
6. **日志轮转** - 防止磁盘占满
7. **资源限制** - 防止单个容器占用过多资源

### ❌ 避免做法

1. **不要在镜像中存储敏感信息** - 使用 secrets
2. **不要使用 latest 标签** - 使用具体版本
3. **不要在容器中存储数据** - 使用卷
4. **不要安装不必要的包** - 保持镜像精简
5. **不要以 root 用户运行** - 安全风险

---

**相关资源**:
- [Docker 官方文档](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/)
- [Dockerfile 最佳实践](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
