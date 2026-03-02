from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="python-deployment-demo",
    version="1.0.0",
    author="Your Name",
    author_email="your.email@example.com",
    description="Python 项目部署示例应用",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/python-deployment-demo",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Topic :: Software Development :: Build Tools",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
    ],
    python_requires=">=3.9",
    install_requires=[
        "Flask>=3.0.0",
        "python-dotenv>=1.0.0",
        "gunicorn>=21.2.0",
        "redis>=5.0.1",
    ],
    extras_require={
        "dev": [
            "black>=23.12.1",
            "flake8>=7.0.0",
            "mypy>=1.8.0",
            "pylint>=3.0.3",
            "pytest>=7.4.3",
            "pytest-cov>=4.1.0",
            "pytest-mock>=3.12.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "run-app=run:main",
        ],
    },
)
