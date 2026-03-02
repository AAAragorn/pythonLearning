#!/bin/bash
set -e

echo "=========================================="
echo "运行测试套件"
echo "=========================================="

# 激活虚拟环境（如果存在）
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# 运行代码格式检查
echo ">>> 运行 Black 代码格式检查..."
black --check app tests || {
    echo "代码格式不符合规范，运行 'black app tests' 进行格式化"
    exit 1
}

# 运行代码风格检查
echo ">>> 运行 Flake8 代码风格检查..."
flake8 app tests --max-line-length=127 --extend-ignore=E203,W503

# 运行类型检查
echo ">>> 运行 MyPy 类型检查..."
mypy app --ignore-missing-imports || true

# 运行单元测试
echo ">>> 运行单元测试..."
pytest tests/ -v --cov=app --cov-report=html --cov-report=term-missing

# 显示覆盖率报告位置
echo ""
echo "=========================================="
echo "测试完成！"
echo "HTML 覆盖率报告: htmlcov/index.html"
echo "=========================================="
