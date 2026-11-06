from datetime import datetime, timezone
import uuid
from typing import Dict, List
from fastapi import APIRouter, HTTPException, status

from app.schemas.job import JobCreate, JobListResponse, JobResponse, JobStatus

router = APIRouter(prefix="/jobs", tags=["Jobs"])

# In-memory store for jobs
jobs_db: Dict[str, JobResponse] = {}


@router.post(
    "",
    response_model=JobResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit a new AI analysis job",
)
async def create_job(job_in: JobCreate):
    """
    Register and queue a new video analysis or proof verification job.
    """
    job_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    
    job = JobResponse(
        job_id=job_id,
        status=JobStatus.PENDING,
        job_type=job_in.job_type,
        listing_id=job_in.listing_id,
        video_url=job_in.video_url,
        created_at=now,
        updated_at=now,
    )
    jobs_db[job_id] = job
    return job


@router.get(
    "",
    response_model=JobListResponse,
    summary="List all AI analysis jobs",
)
async def list_jobs():
    """
    Retrieve all registered AI jobs.
    """
    job_list = list(jobs_db.values())
    return JobListResponse(total=len(job_list), jobs=job_list)


@router.get(
    "/{job_id}",
    response_model=JobResponse,
    summary="Get status and details of a specific AI job",
)
async def get_job(job_id: str):
    """
    Query the real-time execution status and results of a job by ID.
    """
    if job_id not in jobs_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Job with ID '{job_id}' not found",
        )
    return jobs_db[job_id]


@router.delete(
    "/{job_id}",
    status_code=status.HTTP_200_OK,
    summary="Cancel or delete an analysis job",
)
async def delete_job(job_id: str):
    """
    Remove or cancel a job from tracking.
    """
    if job_id not in jobs_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Job with ID '{job_id}' not found",
        )
    deleted_job = jobs_db.pop(job_id)
    return {"message": f"Job '{deleted_job.job_id}' deleted successfully"}
