# 变更日志

本文档记录项目的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

### 新增
- 完整的项目结构
- Flask Web 应用示例
- Docker 和 Docker Compose 配置
- GitHub Actions CI/CD 流程
- 部署脚本和工具
- 完整的文档

### 变更
- 无

### 修复
- 无

## [1.0.0] - 2026-03-02

### 新增
- 初始版本发布
- 基础 Flask 应用
- 健康检查端点
- RESTful API 示例
- 单元测试
- Docker 容器化支持
- Nginx 反向代理配置
- PostgreSQL 和 Redis 集成
- CI/CD 自动化流程
- 完整部署文档

### 应用功能
- `GET /` - 应用首页
- `GET /health` - 健康检查
- `GET /api/data` - 获取数据列表
- `POST /api/data` - 提交数据

### 基础设施
- Python 3.9+ 支持
- Docker 多阶段构建
- Docker Compose 编排
- Gunicorn WSGI 服务器
- Nginx 反向代理
- GitHub Actions 工作流

### 文档
- README.md - 项目说明
- DEPLOYMENT.md - 部署教程
- docs/环境准备.md - 环境配置指南
- docs/项目结构说明.md - 代码组织说明
- docs/Docker部署指南.md - 容器化部署
- docs/CI-CD配置指南.md - 自动化流程

### 脚本工具
- scripts/setup-server.sh - 服务器初始化
- scripts/deploy.sh - 自动化部署
- scripts/local-dev.sh - 本地开发环境
- scripts/test.sh - 测试运行器
- Makefile - 快捷命令

---

## 版本说明

### 版本号规则

给定版本号 MAJOR.MINOR.PATCH，递增规则如下：

1. **MAJOR（主版本号）**：当做了不兼容的 API 修改
2. **MINOR（次版本号）**：当做了向下兼容的功能性新增
3. **PATCH（修订号）**：当做了向下兼容的问题修正

### 变更类型

- **新增（Added）**：新功能
- **变更（Changed）**：已有功能的变更
- **弃用（Deprecated）**：即将移除的功能
- **移除（Removed）**：已移除的功能
- **修复（Fixed）**：Bug 修复
- **安全（Security）**：安全相关的修复

---

[未发布]: https://github.com/yourusername/yourrepo/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/yourrepo/releases/tag/v1.0.0
