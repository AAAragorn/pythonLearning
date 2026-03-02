"""
数据库连接和操作
"""
from databases import Database
from sqlalchemy import create_engine, MetaData, Table, Column, Integer, String, Float, DateTime
from app.config import settings

database = Database(settings.DATABASE_URL)
metadata = MetaData()

items = Table(
    "items",
    metadata,
    Column("id", Integer, primary_key=True, autoincrement=True),
    Column("name", String(100), nullable=False),
    Column("description", String(500)),
    Column("price", Float, nullable=False),
    Column("created_at", DateTime, nullable=False),
)

engine = create_engine(settings.DATABASE_URL)


def init_db():
    """初始化数据库表"""
    metadata.create_all(engine)
