"""WSGI 入口文件，用于 Gunicorn 等 WSGI 服务器"""
from app import create_app

app = create_app()

if __name__ == "__main__":
    app.run()
