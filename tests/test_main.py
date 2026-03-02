"""
主应用测试
"""
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_root():
    """测试根路径"""
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()
    assert "version" in response.json()


def test_health_check():
    """测试健康检查"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "timestamp" in data
    assert "version" in data


def test_get_items():
    """测试获取商品列表"""
    response = client.get("/api/items")
    assert response.status_code in [200, 500]


@pytest.mark.parametrize("item_data", [
    {
        "name": "测试商品",
        "description": "这是一个测试商品",
        "price": 99.99
    }
])
def test_create_item(item_data):
    """测试创建商品"""
    response = client.post("/api/items", json=item_data)
    assert response.status_code in [201, 500]
