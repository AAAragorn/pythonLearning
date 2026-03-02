# 快速部署指南

本文档提供了快速部署步骤，适合有一定经验的开发者。如需详细说明，请查看 [README.md](README.md)。

## 目录

- [本地开发部署](#本地开发部署)
- [Docker 快速部署](#docker-快速部署)
- [生产服务器部署](#生产服务器部署)
- [CI/CD 配置](#cicd-配置)

---

## 本地开发部署

### 方式一：使用 Docker Compose (推荐)

```bash
# 1. 克隆项目
git clone <your-repo-url>
cd python-deployment

# 2. 启动开发环境
docker compose -f docker-compose.dev.yml up -d

# 3. 访问应用
open http://localhost:8000/docs
```

### 方式二：本地 Python 环境

```bash
# 1. 创建虚拟环境
python -m venv venv
source venv/bin/activate

# 2. 安装依赖
pip install -r requirements-dev.txt

# 3. 配置环境变量
cp .env.example .env

# 4. 启动数据库
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=appdb \
  -p 5432:5432 \
  postgres:15-alpine

# 5. 运行应用
uvicorn app.main:app --reload
```

---

## Docker 快速部署

### 单个容器部署

```bash
# 构建镜像
docker build -t python-app:latest .

# 运行容器
docker run -d \
  --name python-app \
  -p 8000:8000 \
  -e DATABASE_URL=postgresql://user:pass@host/db \
  python-app:latest
```

### 完整栈部署 (推荐)

```bash
# 1. 配置环境变量
cp .env.example .env
vim .env

# 2. 启动所有服务
docker compose up -d

# 3. 初始化数据库
docker compose exec app python -c "from app.database import init_db; init_db()"

# 4. 检查状态
docker compose ps
curl http://localhost:8000/health
```

---

## 生产服务器部署

### 一键部署脚本

```bash
# 在服务器上执行
curl -sSL https://raw.githubusercontent.com/yourusername/python-deployment/main/scripts/setup.sh | sudo bash

cd /opt
git clone <your-repo-url> app
cd app

# 配置环境变量
cp .env.example .env
vim .env

# 部署
bash scripts/deploy.sh
```

### 手动部署步骤

#### 1. 安装 Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

#### 2. 克隆代码

```bash
sudo mkdir -p /opt/app
sudo chown $USER:$USER /opt/app
cd /opt/app
git clone <your-repo-url> .
```

#### 3. 配置应用

```bash
cp .env.example .env
# 编辑 .env 文件，设置生产环境配置
vim .env
```

必须修改的配置：
```env
DEBUG=False
SECRET_KEY=<生成一个强密码>
DATABASE_URL=postgresql://user:password@localhost:5432/proddb
```

生成安全的 SECRET_KEY：
```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

#### 4. 启动服务

```bash
docker compose up -d
```

#### 5. 配置 Nginx 和 SSL

```bash
# 安装 Certbot
sudo apt install certbot

# 获取 SSL 证书
sudo certbot certonly --standalone -d yourdomain.com

# 更新 Nginx 配置
vim nginx/conf.d/app.conf
# 修改 server_name 和 SSL 证书路径

# 重启 Nginx
docker compose restart nginx
```

#### 6. 设置防火墙

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

---

## CI/CD 配置

### GitHub Actions

#### 1. 配置 Secrets

在 GitHub 仓库中设置以下 Secrets (Settings > Secrets and variables > Actions):

| Secret | 描述 | 示例 |
|--------|------|------|
| `DOCKER_USERNAME` | Docker Hub 用户名 | `myusername` |
| `DOCKER_PASSWORD` | Docker Hub 访问令牌 | `dckr_pat_xxx` |
| `SERVER_HOST` | 服务器地址 | `123.45.67.89` |
| `SERVER_USER` | SSH 用户名 | `ubuntu` |
| `SSH_PRIVATE_KEY` | SSH 私钥 | `-----BEGIN...` |

#### 2. 生成 SSH 密钥

```bash
# 本地生成密钥对
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions

# 将公钥添加到服务器
ssh-copy-id -i ~/.ssh/github_actions.pub user@server

# 复制私钥内容到 GitHub Secrets
cat ~/.ssh/github_actions
```

#### 3. 触发部署

```bash
# 提交代码到 main 分支自动触发
git push origin main

# 或在 GitHub Actions 页面手动触发
```

### GitLab CI/CD

#### 1. 配置变量

在 GitLab 项目中设置变量 (Settings > CI/CD > Variables):

- `DOCKER_REGISTRY_USER`
- `DOCKER_REGISTRY_PASSWORD`
- `SSH_PRIVATE_KEY`
- `SERVER_HOST`
- `SERVER_USER`

#### 2. 启用 Runner

确保项目已启用 GitLab Runner

#### 3. 部署

```bash
git push origin main
```

---

## 常用命令速查

### Docker Compose

```bash
# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 查看日志
docker compose logs -f

# 重启服务
docker compose restart

# 查看状态
docker compose ps

# 执行命令
docker compose exec app python manage.py shell
```

### 数据库

```bash
# 连接数据库
docker compose exec db psql -U postgres appdb

# 备份数据库
docker compose exec db pg_dump -U postgres appdb > backup.sql

# 恢复数据库
docker compose exec -T db psql -U postgres appdb < backup.sql

# 查看数据库大小
docker compose exec db psql -U postgres -c "\l+"
```

### 应用管理

```bash
# 查看应用日志
docker compose logs -f app

# 重启应用
docker compose restart app

# 进入应用容器
docker compose exec app bash

# 运行测试
docker compose exec app pytest

# 健康检查
curl http://localhost:8000/health
```

### 监控和维护

```bash
# 查看资源使用
docker stats

# 清理未使用的资源
docker system prune -a

# 查看磁盘使用
df -h

# 查看内存使用
free -h
```

---

## 故障排查

### 容器无法启动

```bash
# 查看详细日志
docker compose logs app

# 检查配置文件
docker compose config

# 检查端口占用
sudo lsof -i :8000
```

### 数据库连接失败

```bash
# 检查数据库容器
docker compose ps db
docker compose logs db

# 测试数据库连接
docker compose exec db psql -U postgres -c "SELECT 1"

# 检查环境变量
docker compose exec app env | grep DATABASE
```

### Nginx 502 错误

```bash
# 检查应用是否运行
docker compose ps app

# 测试应用健康
curl http://localhost:8000/health

# 检查 Nginx 配置
docker compose exec nginx nginx -t

# 查看 Nginx 日志
docker compose logs nginx
```

---

## 性能优化建议

### 1. 应用优化

- 使用 Gunicorn workers 配置（已配置 4 个 workers）
- 启用 Redis 缓存
- 数据库连接池优化
- 静态文件使用 CDN

### 2. Docker 优化

- 使用多阶段构建（已实现）
- 优化镜像层缓存
- 限制容器资源使用

```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

### 3. 数据库优化

- 定期备份
- 配置适当的索引
- 启用查询缓存
- 使用连接池

### 4. 监控配置

建议安装：
- Prometheus - 指标收集
- Grafana - 可视化监控
- Sentry - 错误追踪
- ELK Stack - 日志分析

---

## 安全检查清单

- [ ] 修改默认密码和密钥
- [ ] 启用 HTTPS/SSL
- [ ] 配置防火墙规则
- [ ] 限制 SSH 访问（使用密钥，禁用密码）
- [ ] 定期更新系统和依赖
- [ ] 配置自动备份
- [ ] 启用日志审计
- [ ] 使用环境变量管理敏感信息
- [ ] 限制容器权限（非 root 运行）
- [ ] 配置 CORS 策略

---

## 下一步

1. **本地开发**: 完成后阅读 [开发指南](README.md#4-本地开发)
2. **生产部署**: 完成后配置 [监控和备份](README.md#8-监控与维护)
3. **CI/CD**: 配置自动化流程 [CI/CD 流程](README.md#7-cicd-流程)
4. **优化**: 根据实际情况进行 [性能优化](README.md#10-最佳实践)

---

**需要帮助？** 查看 [常见问题](README.md#9-常见问题) 或提交 Issue。
