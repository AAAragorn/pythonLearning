#!/bin/bash
set -e

echo "=========================================="
echo "本地开发环境启动脚本"
echo "=========================================="

# 检查 Python 版本
if ! command -v python3 &> /dev/null; then
    echo "错误: Python 3 未安装"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "Python 版本: $PYTHON_VERSION"

# 创建虚拟环境
if [ ! -d "venv" ]; then
    echo "创建虚拟环境..."
    python3 -m venv venv
fi

# 激活虚拟环境
echo "激活虚拟环境..."
source venv/bin/activate

# 安装依赖
echo "安装依赖..."
pip install --upgrade pip
pip install -r requirements-dev.txt

# 复制环境变量文件
if [ ! -f ".env" ]; then
    echo "创建 .env 文件..."
    cp .env.example .env
    echo "请编辑 .env 文件配置环境变量"
fi

# 运行测试
echo "运行测试..."
pytest tests/ -v

# 启动应用
echo "启动开发服务器..."
python run.py
