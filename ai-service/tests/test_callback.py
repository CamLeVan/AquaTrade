from datetime import datetime, timezone
import pytest
from unittest.mock import AsyncMock, patch

from app.schemas.job import JobResponse, JobResult, JobStatus, JobType
from app.services.callback_service import CallbackService


def test_build_callback_payload():
    now = datetime.now(timezone.utc)
    job = JobResponse(
        job_id="test-job-cb-1",
        status=JobStatus.COMPLETED,
        job_type=JobType.FISH_ANALYSIS,
        listing_id="listing-777",
        video_url="video.mp4",
        created_at=now,
        updated_at=now,
        result=JobResult(
            fish_count=20,
            confidence_score=0.95,
            proof_hash="abcd1234proofhash",
            annotated_video_url="output.mp4",
            completed_at=now,
        ),
    )

    payload = CallbackService.build_payload(job)
    assert payload["job_id"] == "test-job-cb-1"
    assert payload["listing_id"] == "listing-777"
    assert payload["status"] == "COMPLETED"
    assert payload["fish_count"] == 20
    assert payload["confidence_score"] == 0.95
    assert payload["proof_hash"] == "abcd1234proofhash"


@pytest.mark.asyncio
async def test_callback_service_no_url():
    service = CallbackService(default_callback_url="")
    now = datetime.now(timezone.utc)
    job = JobResponse(
        job_id="test-no-url",
        status=JobStatus.COMPLETED,
        job_type=JobType.FISH_ANALYSIS,
        created_at=now,
        updated_at=now,
    )
    res = await service.send_callback(job, target_url=None)
    assert res["success"] is False
    assert res["attempts"] == 0
