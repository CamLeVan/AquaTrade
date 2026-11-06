from fastapi import APIRouter
from app.api.v1.endpoints import health, jobs, model

api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(jobs.router)
api_router.include_router(model.router)
