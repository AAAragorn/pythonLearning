.PHONY: help install install-dev test lint format clean run dev build deploy

help:
	@echo "Python 部署项目 - 可用命令："
	@echo ""
	@echo "开发相关："
	@echo "  make install        - 安装生产依赖"
	@echo "  make install-dev    - 安装开发依赖"
	@echo "  make dev            - 启动开发环境（Docker）"
	@echo "  make run            - 运行应用（本地）"
	@echo ""
	@echo "代码质量："
	@echo "  make test           - 运行测试"
	@echo "  make lint           - 代码检查"
	@echo "  make format         - 格式化代码"
	@echo ""
	@echo "Docker 相关："
	@echo "  make build          - 构建 Docker 镜像"
	@echo "  make up             - 启动所有服务"
	@echo "  make down           - 停止所有服务"
	@echo "  make logs           - 查看日志"
	@echo ""
	@echo "部署相关："
	@echo "  make deploy         - 部署到生产环境"
	@echo "  make rollback       - 回滚版本"
	@echo "  make monitor        - 查看监控信息"
	@echo ""
	@echo "清理："
	@echo "  make clean          - 清理临时文件"

install:
	pip install -r requirements.txt

install-dev:
	pip install -r requirements-dev.txt

test:
	pytest tests/ -v --cov=app --cov-report=html

lint:
	flake8 app tests --max-line-length=100 --extend-ignore=E203,W503
	mypy app --ignore-missing-imports

format:
	black app tests
	isort app tests

clean:
	find . -type f -name '*.pyc' -delete
	find . -type d -name '__pycache__' -delete
	find . -type d -name '*.egg-info' -exec rm -rf {} +
	rm -rf .pytest_cache .coverage htmlcov/ dist/ build/

run:
	uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

dev:
	docker compose -f docker-compose.dev.yml up

build:
	docker build -t python-app:latest .

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

restart:
	docker compose restart

ps:
	docker compose ps

deploy:
	bash scripts/deploy.sh

rollback:
	bash scripts/rollback.sh

monitor:
	bash scripts/monitor.sh

db-backup:
	docker compose exec db pg_dump -U postgres appdb > backup_$$(date +%Y%m%d_%H%M%S).sql

db-restore:
	@echo "Usage: make db-restore FILE=backup_20240101.sql"
	docker compose exec -T db psql -U postgres appdb < $(FILE)

shell:
	docker compose exec app bash

db-shell:
	docker compose exec db psql -U postgres appdb
