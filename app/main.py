"""
FastAPI 应用主文件
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import logging
from datetime import datetime

from app.config import settings
from app.database import database

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.VERSION,
    description="Python 项目部署示例应用"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class Item(BaseModel):
    id: Optional[int] = None
    name: str
    description: Optional[str] = None
    price: float
    created_at: Optional[datetime] = None


class HealthResponse(BaseModel):
    status: str
    timestamp: datetime
    version: str
    database: str


@app.on_event("startup")
async def startup():
    logger.info("应用启动中...")
    await database.connect()
    logger.info("数据库连接成功")


@app.on_event("shutdown")
async def shutdown():
    logger.info("应用关闭中...")
    await database.disconnect()
    logger.info("数据库连接已关闭")


@app.get("/")
async def root():
    return {
        "message": "欢迎使用 Python 部署示例项目",
        "version": settings.VERSION,
        "docs": "/docs"
    }


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """健康检查端点"""
    db_status = "connected" if database.is_connected else "disconnected"
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now(),
        version=settings.VERSION,
        database=db_status
    )


@app.get("/api/items", response_model=List[Item])
async def get_items():
    """获取所有商品"""
    query = "SELECT * FROM items ORDER BY created_at DESC"
    items = await database.fetch_all(query)
    return items


@app.get("/api/items/{item_id}", response_model=Item)
async def get_item(item_id: int):
    """获取单个商品"""
    query = "SELECT * FROM items WHERE id = :item_id"
    item = await database.fetch_one(query, {"item_id": item_id})
    if not item:
        raise HTTPException(status_code=404, detail="商品不存在")
    return item


@app.post("/api/items", response_model=Item, status_code=201)
async def create_item(item: Item):
    """创建新商品"""
    query = """
        INSERT INTO items (name, description, price, created_at)
        VALUES (:name, :description, :price, :created_at)
        RETURNING *
    """
    values = {
        "name": item.name,
        "description": item.description,
        "price": item.price,
        "created_at": datetime.now()
    }
    new_item = await database.fetch_one(query, values)
    return new_item


@app.put("/api/items/{item_id}", response_model=Item)
async def update_item(item_id: int, item: Item):
    """更新商品"""
    query = """
        UPDATE items
        SET name = :name, description = :description, price = :price
        WHERE id = :item_id
        RETURNING *
    """
    values = {
        "item_id": item_id,
        "name": item.name,
        "description": item.description,
        "price": item.price
    }
    updated_item = await database.fetch_one(query, values)
    if not updated_item:
        raise HTTPException(status_code=404, detail="商品不存在")
    return updated_item


@app.delete("/api/items/{item_id}")
async def delete_item(item_id: int):
    """删除商品"""
    query = "DELETE FROM items WHERE id = :item_id RETURNING id"
    deleted = await database.fetch_one(query, {"item_id": item_id})
    if not deleted:
        raise HTTPException(status_code=404, detail="商品不存在")
    return {"message": "商品已删除", "id": item_id}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
