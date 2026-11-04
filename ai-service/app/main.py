from datetime import datetime, timezone
from uuid import uuid4

from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, HttpUrl

app = FastAPI(title="AquaTrade AI Service", version="0.1.0")
jobs: dict[str, dict] = {}


class AnalysisJobRequest(BaseModel):
    source_url: HttpUrl
    callback_url: HttpUrl | None = None


@app.get("/ai/v1/health")
def health() -> dict:
    return {
        "service": "aquatrade-ai-service",
        "status": "UP",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.post("/ai/v1/jobs", status_code=status.HTTP_202_ACCEPTED)
def create_analysis_job(request: AnalysisJobRequest) -> dict:
    job_id = str(uuid4())
    jobs[job_id] = {
        "job_id": job_id,
        "status": "QUEUED",
        "source_url": str(request.source_url),
        "callback_url": str(request.callback_url) if request.callback_url else None,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    return jobs[job_id]


@app.get("/ai/v1/jobs/{job_id}")
def get_analysis_job(job_id: str) -> dict:
    job = jobs.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Analysis job not found")
    return job
