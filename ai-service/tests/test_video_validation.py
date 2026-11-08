import io
import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

# Minimal mock MP4 header with 'ftyp' at offset 4
MOCK_MP4_HEADER = b"\x00\x00\x00\x20ftypisom\x00\x00\x02\x00isomiso2avc1mp41" + b"\x00" * 100


def test_upload_valid_video():
    file_bytes = io.BytesIO(MOCK_MP4_HEADER)
    response = client.post(
        "/api/v1/jobs/upload",
        files={"file": ("test_fish.mp4", file_bytes, "video/mp4")},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["filename"] == "test_fish.mp4"
    assert data["content_type"] == "video/mp4"
    assert data["file_size_bytes"] > 0
    assert "saved_path" in data


def test_upload_invalid_extension():
    file_bytes = io.BytesIO(b"malicious script content")
    response = client.post(
        "/api/v1/jobs/upload",
        files={"file": ("malicious.exe", file_bytes, "application/octet-stream")},
    )
    assert response.status_code == 400
    assert "Unsupported video extension" in response.json()["detail"]


def test_upload_empty_video():
    file_bytes = io.BytesIO(b"")
    response = client.post(
        "/api/v1/jobs/upload",
        files={"file": ("empty.mp4", file_bytes, "video/mp4")},
    )
    assert response.status_code == 400
    assert "Uploaded file is empty" in response.json()["detail"]


def test_upload_invalid_magic_bytes():
    file_bytes = io.BytesIO(b"This is just plain text disguised as an mp4 file.")
    response = client.post(
        "/api/v1/jobs/upload",
        files={"file": ("fake.mp4", file_bytes, "video/mp4")},
    )
    assert response.status_code == 400
    assert "binary format signatures" in response.json()["detail"]


def test_upload_and_analyze_endpoint():
    file_bytes = io.BytesIO(MOCK_MP4_HEADER)
    response = client.post(
        "/api/v1/jobs/upload-and-analyze",
        files={"file": ("fish_sample.mp4", file_bytes, "video/mp4")},
        data={"listing_id": "listing-999", "job_type": "FISH_ANALYSIS"},
    )
    assert response.status_code == 201
    job = response.json()
    assert job["status"] == "PENDING"
    assert job["listing_id"] == "listing-999"
    assert job["video_url"] is not None
