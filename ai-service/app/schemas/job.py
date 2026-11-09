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


class DigitalProofManifest(BaseModel):
    version: str = "1.0"
    algorithm: str = "SHA-256"
    job_id: str
    listing_id: Optional[str] = None
    video_sha256: str
    fish_count: int
    confidence_score: float
    model_version: str
    verified_at: str
    proof_hash: str


class JobResult(BaseModel):
    fish_count: Optional[int] = Field(None, description="Detected number of fish")
    confidence_score: Optional[float] = Field(None, description="Average detection confidence score")
    proof_hash: Optional[str] = Field(None, description="SHA-256 digital proof signature")
    annotated_video_url: Optional[str] = Field(None, description="Path to generated annotated verification video")
    proof_manifest: Optional[DigitalProofManifest] = None
    completed_at: Optional[datetime] = None



class JobResponse(BaseModel):
    job_id: str
    status: JobStatus
    job_type: JobType
    listing_id: Optional[str] = None
    video_url: Optional[str] = None
    progress: float = Field(default=0.0, ge=0.0, le=100.0, description="Progress percentage (0.0 to 100.0)")
    stage: str = Field(default="PENDING", description="Current execution stage")
    created_at: datetime
    updated_at: datetime
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    result: Optional[JobResult] = None
    error: Optional[str] = None


class JobStatusResponse(BaseModel):
    job_id: str
    status: JobStatus
    progress: float
    stage: str
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
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

