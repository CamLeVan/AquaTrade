from datetime import datetime, timezone
import uuid
from typing import Dict, List, Optional
from fastapi import APIRouter, File, Form, HTTPException, UploadFile, status

from app.schemas.job import (
    JobCreate,
    JobListResponse,
    JobResponse,
    JobStatus,
    JobType,
    VideoMetadataResponse,
    VideoUploadResponse,
)
from app.services.frame_extractor import frame_extractor
from app.services.video_validation import save_uploaded_video, validate_video_file

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


@router.post(
    "/upload",
    response_model=VideoUploadResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload and validate a video file for analysis",
)
async def upload_video(file: UploadFile = File(...)):
    """
    Upload and validate a video file against allowed extensions, MIME types,
    maximum file size, and header binary signatures.
    """
    validation_info = await validate_video_file(file)
    saved_path, size_bytes = await save_uploaded_video(file)
    
    return VideoUploadResponse(
        filename=validation_info["filename"],
        saved_path=saved_path,
        file_size_bytes=size_bytes,
        content_type=validation_info["content_type"],
        message="Video uploaded and validated successfully.",
    )


@router.post(
    "/upload-and-analyze",
    response_model=JobResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload video and queue an analysis job in one step",
)
async def upload_and_analyze(
    file: UploadFile = File(...),
    listing_id: Optional[str] = Form(None),
    job_type: JobType = Form(JobType.FISH_ANALYSIS),
):
    """
    Uploads and validates a video file, then immediately registers a pending analysis job.
    """
    await validate_video_file(file)
    saved_path, _ = await save_uploaded_video(file)

    job_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)

    job = JobResponse(
        job_id=job_id,
        status=JobStatus.PENDING,
        job_type=job_type,
        listing_id=listing_id,
        video_url=saved_path,
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


@router.get(
    "/{job_id}/metadata",
    response_model=VideoMetadataResponse,
    summary="Extract and view video metadata for a specific job",
)
async def get_job_video_metadata(job_id: str):
    """
    Extracts frame rate, total frames, resolution, and duration of the job's video.
    """
    if job_id not in jobs_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Job with ID '{job_id}' not found",
        )
    job = jobs_db[job_id]
    if not job.video_url:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Job does not have an associated video path/URL.",
        )
    try:
        metadata = frame_extractor.get_metadata(job.video_url)
        return VideoMetadataResponse(
            total_frames=metadata.total_frames,
            fps=metadata.fps,
            duration_seconds=metadata.duration_seconds,
            width=metadata.width,
            height=metadata.height,
            codec=metadata.codec,
        )
    except FileNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Video file does not exist on disk.",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to read video metadata: {str(e)}",
        )



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
