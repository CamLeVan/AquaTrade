import asyncio
import io
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.schemas.job import JobStatus

client = TestClient(app)

MOCK_MP4_HEADER = b"\x00\x00\x00\x20ftypisom\x00\x00\x02\x00isomiso2avc1mp41" + b"\x00" * 100


def test_async_job_creation_and_status():
    # 1. Create job with auto_start=False
    payload = {
        "listing_id": "listing-async-1",
        "video_url": "test_sample.mp4",
        "job_type": "FISH_ANALYSIS",
    }
    res = client.post("/api/v1/jobs?auto_start=false", json=payload)
    assert res.status_code == 201
    job = res.json()
    job_id = job["job_id"]
    assert job["status"] == "PENDING"
    assert job["progress"] == 0.0

    # 2. Check initial status via status tracking endpoint
    status_res = client.get(f"/api/v1/jobs/{job_id}/status")
    assert status_res.status_code == 200
    st = status_res.json()
    assert st["job_id"] == job_id
    assert st["status"] == "PENDING"
    assert st["progress"] == 0.0

    # 3. Manually dispatch job to background worker
    start_res = client.post(f"/api/v1/jobs/{job_id}/start")
    assert start_res.status_code == 200
    start_data = start_res.json()
    assert start_data["job_id"] == job_id
    assert start_data["stage"] == "DISPATCHED"


def test_upload_and_analyze_async():
    file_bytes = io.BytesIO(MOCK_MP4_HEADER)
    res = client.post(
        "/api/v1/jobs/upload-and-analyze",
        files={"file": ("fish_tracking_test.mp4", file_bytes, "video/mp4")},
        data={"listing_id": "listing-async-2"},
    )
    assert res.status_code == 201
    job = res.json()
    job_id = job["job_id"]
    assert job["job_id"] is not None

    # Status tracking should be available immediately
    status_res = client.get(f"/api/v1/jobs/{job_id}/status")
    assert status_res.status_code == 200
    assert status_res.json()["job_id"] == job_id
