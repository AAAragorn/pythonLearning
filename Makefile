.PHONY: help install install-dev test lint format clean run docker-build docker-up docker-down deploy

help:
	@echo "可用命令:"
	@echo "  make install        - 安装生产依赖"
	@echo "  make install-dev    - 安装开发依赖"
	@echo "  make test           - 运行测试"
	@echo "  make lint           - 运行代码检查"
	@echo "  make format         - 格式化代码"
	@echo "  make clean          - 清理临时文件"
	@echo "  make run            - 运行开发服务器"
	@echo "  make docker-build   - 构建 Docker 镜像"
	@echo "  make docker-up      - 启动 Docker 容器"
	@echo "  make docker-down    - 停止 Docker 容器"
	@echo "  make deploy         - 部署到生产环境"

install:
	pip install -r requirements.txt

install-dev:
	pip install -r requirements-dev.txt

test:
	pytest tests/ -v --cov=app --cov-report=html --cov-report=term-missing

lint:
	flake8 app tests --max-line-length=127
	mypy app --ignore-missing-imports
	black --check app tests

format:
	black app tests
	isort app tests

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	rm -rf build dist .coverage htmlcov/ .pytest_cache/ .mypy_cache/

run:
	python run.py

docker-build:
	docker build -t python-app:latest .

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f

deploy:
	bash scripts/deploy.sh

setup-server:
	bash scripts/setup-server.sh
