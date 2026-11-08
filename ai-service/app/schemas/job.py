from datetime import datetime, timezone
from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class JobStatus(str, Enum):
    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"


class JobType(str, Enum):
    FISH_ANALYSIS = "FISH_ANALYSIS"
    PROOF_VERIFICATION = "PROOF_VERIFICATION"


class JobCreate(BaseModel):
    listing_id: Optional[str] = Field(None, description="Associated fish listing ID")
    video_url: Optional[str] = Field(None, description="URL or path of the video for analysis")
    callback_url: Optional[str] = Field(None, description="Backend webhook callback URL upon completion")
    job_type: JobType = Field(default=JobType.FISH_ANALYSIS, description="Type of AI analysis task")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Custom metadata for the job")


class JobResult(BaseModel):
    fish_count: Optional[int] = Field(None, description="Detected number of fish")
    confidence_score: Optional[float] = Field(None, description="Average detection confidence score")
    proof_hash: Optional[str] = Field(None, description="SHA-256 digital proof signature")
    annotated_video_url: Optional[str] = Field(None, description="Path to generated annotated verification video")
    completed_at: Optional[datetime] = None


class JobResponse(BaseModel):
    job_id: str
    status: JobStatus
    job_type: JobType
    listing_id: Optional[str] = None
    video_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    result: Optional[JobResult] = None
    error: Optional[str] = None


class JobListResponse(BaseModel):
    total: int
    jobs: List[JobResponse]


class VideoUploadResponse(BaseModel):
    filename: str = Field(..., description="Original video filename")
    saved_path: str = Field(..., description="Local storage path of saved video")
    file_size_bytes: int = Field(..., description="File size in bytes")
    content_type: str = Field(..., description="MIME content type")
    message: str = Field(default="Video uploaded and validated successfully")


class VideoMetadataResponse(BaseModel):
    total_frames: int
    fps: float
    duration_seconds: float
    width: int
    height: int
    codec: str

