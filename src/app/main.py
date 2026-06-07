"""
src/app/main.py
───────────────
CD-010 Sample FastAPI Application
Used as the subject of the GitHub Actions CI/CD pipeline.
Demonstrates: health endpoint, versioned API, structured logging.
"""

from __future__ import annotations

import os
from datetime import datetime, timezone

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# ── App metadata ──────────────────────────────────────────────────────────────
APP_VERSION = os.environ.get("APP_VERSION", "0.0.0")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "development")
GIT_SHA     = os.environ.get("GIT_SHA", "unknown")

app = FastAPI(
    title="CD-010 App",
    description="Sample app for CD-010 GitHub Actions Advanced CI/CD pipeline",
    version=APP_VERSION,
    docs_url="/docs" if ENVIRONMENT != "production" else None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

# ── Models ────────────────────────────────────────────────────────────────────
class HealthResponse(BaseModel):
    status:      str
    version:     str
    environment: str
    git_sha:     str
    timestamp:   str

class Item(BaseModel):
    id:    int
    name:  str
    value: float

# ── In-memory store (demo only) ───────────────────────────────────────────────
_items: dict[int, Item] = {
    1: Item(id=1, name="GitHub Actions",  value=100.0),
    2: Item(id=2, name="AWS Lambda",      value=95.0),
    3: Item(id=3, name="Terraform",       value=90.0),
    4: Item(id=4, name="Docker Buildx",   value=88.0),
    5: Item(id=5, name="ArgoCD GitOps",   value=85.0),
}

# ─────────────────────────────────────────────────────────────────────────────
# ROUTES
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/health", response_model=HealthResponse, tags=["ops"])
def health_check() -> HealthResponse:
    """Health check — used by Docker HEALTHCHECK and K8s liveness probe."""
    return HealthResponse(
        status="healthy",
        version=APP_VERSION,
        environment=ENVIRONMENT,
        git_sha=GIT_SHA,
        timestamp=datetime.now(timezone.utc).isoformat(),
    )


@app.get("/", tags=["root"])
def root() -> dict:
    return {
        "service":     "cd010-app",
        "version":     APP_VERSION,
        "environment": ENVIRONMENT,
        "docs":        "/docs",
    }


@app.get("/items", tags=["items"])
def list_items() -> list[Item]:
    return list(_items.values())


@app.get("/items/{item_id}", tags=["items"])
def get_item(item_id: int) -> Item:
    item = _items.get(item_id)
    if not item:
        raise HTTPException(status_code=404, detail=f"Item {item_id} not found")
    return item


@app.post("/items", tags=["items"], status_code=201)
def create_item(item: Item) -> Item:
    if item.id in _items:
        raise HTTPException(status_code=409, detail=f"Item {item.id} already exists")
    _items[item.id] = item
    return item
