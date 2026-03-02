# 🚀 快速开始

5 分钟内启动你的 Python 项目！

## 选择你的方式

### 🐳 方式一：Docker (推荐 - 最简单)

```bash
# 1. 启动开发环境
docker compose -f docker-compose.dev.yml up -d

# 2. 访问应用
open http://localhost:8000/docs
```

**就这么简单！** 应用、数据库、Redis 全部自动启动。

---

### 💻 方式二：本地 Python 环境

```bash
# 1. 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 2. 安装依赖
pip install -r requirements-dev.txt

# 3. 启动数据库（使用 Docker）
docker run -d --name postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=appdb \
  -p 5432:5432 \
  postgres:15-alpine

# 4. 配置环境变量
cp .env.example .env

# 5. 运行应用
uvicorn app.main:app --reload
```

---

### 📦 方式三：使用 Makefile

```bash
# 安装依赖
make install-dev

# 启动开发环境
make dev

# 运行测试
make test

# 查看所有命令
make help
```

---

## ✅ 验证安装

访问以下地址确认应用正常运行：

- **API 文档**: http://localhost:8000/docs
- **健康检查**: http://localhost:8000/health
- **根路径**: http://localhost:8000

你应该看到 FastAPI 的交互式文档界面。

---

## 📚 下一步

1. **学习 API**: 在 http://localhost:8000/docs 探索 API
2. **查看代码**: 从 `app/main.py` 开始
3. **运行测试**: `pytest` 或 `make test`
4. **阅读教程**: [README.md](README.md) 有完整的部署教程
5. **快速部署**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

## 🛠️ 常用命令

```bash
# 查看日志
docker compose logs -f app

# 停止所有服务
docker compose down

# 重启应用
docker compose restart app

# 进入容器
docker compose exec app bash

# 数据库 Shell
docker compose exec db psql -U postgres appdb
```

---

## 📖 项目结构速览

```
python-deployment/
├── app/              # 应用代码
│   ├── main.py       # FastAPI 应用
│   ├── config.py     # 配置
│   └── database.py   # 数据库
├── tests/            # 测试
├── scripts/          # 部署脚本
├── deployment/       # 部署配置
├── nginx/            # Nginx 配置
└── .github/          # CI/CD
```

---

## ❓ 遇到问题？

### 端口被占用

```bash
# 查看占用端口的进程
sudo lsof -i :8000
# 或修改端口
# 编辑 docker-compose.dev.yml，将 8000:8000 改为 8001:8000
```

### 容器启动失败

```bash
# 查看详细日志
docker compose logs app

# 重新构建
docker compose build --no-cache
docker compose up -d
```

### 数据库连接失败

```bash
# 检查数据库容器
docker compose ps db
docker compose logs db

# 确认数据库就绪
docker compose exec db pg_isready -U postgres
```

---

## 🎯 开发流程

1. **修改代码** - 文件保存后自动重载
2. **运行测试** - `make test`
3. **代码检查** - `make lint`
4. **格式化** - `make format`
5. **提交代码** - `git commit`

---

## 🚀 部署到生产环境

查看 [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) 获取详细的部署步骤。

**快速部署到服务器：**

```bash
# 在服务器上
git clone <your-repo-url> /opt/app
cd /opt/app
cp .env.example .env
vim .env  # 修改为生产配置
bash scripts/deploy.sh
```

---

**祝你开发愉快！** 🎉

有问题？查看 [README.md](README.md#9-常见问题) 的常见问题部分。
