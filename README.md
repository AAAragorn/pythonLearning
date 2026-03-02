# Python 项目部署完整教程

这是一个完整的 Python Web 应用部署示例项目，包含从开发到生产的完整流程。

## 项目简介

本项目展示了一个基于 Flask 的 Web 应用如何进行专业化部署，包括：

- ✅ 标准化的项目结构
- ✅ 完整的依赖管理
- ✅ Docker 容器化部署
- ✅ CI/CD 自动化流程
- ✅ 生产环境最佳实践
- ✅ 详细的部署文档

## 快速开始

### 本地开发

```bash
# 克隆项目
git clone <repository-url>
cd <project-directory>

# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 安装依赖
pip install -r requirements-dev.txt

# 配置环境变量
cp .env.example .env

# 运行测试
pytest tests/

# 启动开发服务器
python run.py
```

访问 http://localhost:5000

### 使用 Docker 开发

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

# 健康检查
./scripts/deploy.sh health
```

## 项目结构

```
.
├── app/                        # 应用主目录
│   ├── __init__.py            # 应用工厂
│   ├── config.py              # 配置管理
│   └── routes.py              # 路由定义
├── tests/                      # 测试目录
├── scripts/                    # 部署脚本
│   ├── deploy.sh              # 部署脚本
│   ├── setup-server.sh        # 服务器初始化
│   └── test.sh                # 测试脚本
├── nginx/                      # Nginx 配置
├── .github/workflows/          # CI/CD 配置
├── docs/                       # 详细文档
├── Dockerfile                  # 生产环境镜像
├── docker-compose.yml          # Docker Compose 配置
├── requirements.txt            # 生产依赖
└── DEPLOYMENT.md               # 部署教程
```

## 主要功能

### API 端点

- `GET /` - 应用首页
- `GET /health` - 健康检查
- `GET /api/data` - 获取数据列表
- `POST /api/data` - 提交数据

### 技术栈

- **Web 框架**: Flask 3.0
- **WSGI 服务器**: Gunicorn
- **反向代理**: Nginx
- **容器化**: Docker & Docker Compose
- **数据库**: PostgreSQL
- **缓存**: Redis
- **CI/CD**: GitHub Actions
- **测试**: Pytest

## 文档

- 📖 [完整部署教程](./DEPLOYMENT.md) - 详细的部署指南
- 🔧 [环境准备](./docs/环境准备.md) - 开发和生产环境配置
- 🐳 [Docker 部署](./DEPLOYMENT.md#5-docker-部署) - 容器化部署指南
- 🚀 [CI/CD 流程](./DEPLOYMENT.md#6-cicd-流程) - 自动化部署流程

## 常用命令

### Makefile 命令

```bash
make install        # 安装生产依赖
make install-dev    # 安装开发依赖
make test           # 运行测试
make lint           # 代码检查
make format         # 格式化代码
make run            # 启动开发服务器
make docker-build   # 构建 Docker 镜像
make docker-up      # 启动 Docker 容器
make deploy         # 部署到生产环境
```

### Docker 命令

```bash
# 构建镜像
docker build -t python-app:latest .

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 进入容器
docker exec -it python-app bash
```

## 部署步骤

### 1. 服务器准备

```bash
# 初始化服务器（一次性）
chmod +x scripts/setup-server.sh
sudo ./scripts/setup-server.sh
```

### 2. 配置环境变量

```bash
cp .env.example .env
vim .env  # 编辑配置
```

### 3. 部署应用

```bash
# 使用部署脚本
./scripts/deploy.sh deploy

# 或使用 Docker Compose
docker-compose up -d
```

### 4. 配置 CI/CD

在 GitHub 仓库设置中配置 Secrets：

- `DEPLOY_HOST` - 服务器地址
- `DEPLOY_USER` - SSH 用户名
- `DEPLOY_KEY` - SSH 私钥
- `DEPLOY_PORT` - SSH 端口

## 监控和维护

### 健康检查

```bash
curl http://your-domain.com/health
./scripts/deploy.sh health
```

### 日志查看

```bash
docker-compose logs -f web
tail -f logs/nginx/access.log
```

## 安全最佳实践

- ✅ 环境变量管理敏感信息
- ✅ SSH 密钥认证
- ✅ 防火墙配置
- ✅ SSL/TLS 加密
- ✅ 依赖安全扫描

## 许可证

MIT License

---

**开始部署你的 Python 应用吧！** 🚀
