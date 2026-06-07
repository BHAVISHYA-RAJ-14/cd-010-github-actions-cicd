"""
tests/unit/test_main.py
───────────────────────
Unit tests for CD-010 FastAPI app.
Used in: ci.yml, matrix-test.yml
Run: pytest tests/unit/ -v
"""

import os
import pytest

os.environ["ENVIRONMENT"]  = "test"
os.environ["APP_VERSION"]  = "0.0.0-test"
os.environ["GIT_SHA"]      = "test-sha"

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestHealthCheck:
    def test_health_returns_200(self):
        res = client.get("/health")
        assert res.status_code == 200

    def test_health_body(self):
        body = client.get("/health").json()
        assert body["status"]      == "healthy"
        assert body["environment"] == "test"
        assert body["version"]     == "0.0.0-test"
        assert "timestamp" in body

    def test_health_has_git_sha(self):
        body = client.get("/health").json()
        assert body["git_sha"] == "test-sha"


class TestRoot:
    def test_root_returns_200(self):
        assert client.get("/").status_code == 200

    def test_root_body(self):
        body = client.get("/").json()
        assert body["service"] == "cd010-app"


class TestItems:
    def test_list_items_returns_200(self):
        assert client.get("/items").status_code == 200

    def test_list_items_returns_list(self):
        body = client.get("/items").json()
        assert isinstance(body, list)
        assert len(body) >= 1

    def test_get_item_exists(self):
        res = client.get("/items/1")
        assert res.status_code == 200
        assert res.json()["id"] == 1

    def test_get_item_not_found(self):
        res = client.get("/items/9999")
        assert res.status_code == 404

    def test_create_item(self):
        res = client.post("/items", json={"id": 99, "name": "Test Item", "value": 42.0})
        assert res.status_code == 201
        assert res.json()["name"] == "Test Item"

    def test_create_item_duplicate(self):
        client.post("/items", json={"id": 98, "name": "Dup", "value": 1.0})
        res = client.post("/items", json={"id": 98, "name": "Dup Again", "value": 2.0})
        assert res.status_code == 409
