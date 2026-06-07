import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

@pytest.mark.integration
def test_api_health():
    response = client.get("/health")
    assert response.status_code == 200
