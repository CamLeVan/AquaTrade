import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.services.yolo_service import yolo_service

client = TestClient(app)


def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "online"
    assert "version" in data
    assert data["api_v1"] == "/api/v1"


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "model_loaded" in data


def test_v1_health_endpoint():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"


def test_model_status_endpoint():
    response = client.get("/api/v1/model/status")
    assert response.status_code == 200
    data = response.json()
    assert data["model_type"] == "YOLOv8"
    assert "is_loaded" in data


def test_jobs_workflow():
    # 1. Create a job
    job_payload = {
        "listing_id": "listing-123",
        "video_url": "https://example.com/videos/fish-batch-01.mp4",
        "job_type": "FISH_ANALYSIS",
        "metadata": {"batch_id": "batch-42"},
    }
    create_res = client.post("/api/v1/jobs", json=job_payload)
    assert create_res.status_code == 201
    job_data = create_res.json()
    job_id = job_data["job_id"]
    assert job_data["status"] == "PENDING"
    assert job_data["listing_id"] == "listing-123"

    # 2. Get the created job
    get_res = client.get(f"/api/v1/jobs/{job_id}")
    assert get_res.status_code == 200
    assert get_res.json()["job_id"] == job_id

    # 3. List jobs
    list_res = client.get("/api/v1/jobs")
    assert list_res.status_code == 200
    list_data = list_res.json()
    assert list_data["total"] >= 1

    # 4. Delete the job
    del_res = client.delete(f"/api/v1/jobs/{job_id}")
    assert del_res.status_code == 200

    # 5. Verify deleted job is 404
    get_del_res = client.get(f"/api/v1/jobs/{job_id}")
    assert get_del_res.status_code == 404
