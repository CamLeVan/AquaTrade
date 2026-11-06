from fastapi import APIRouter
from app.services.yolo_service import yolo_service

router = APIRouter(prefix="/model", tags=["Model"])


@router.get("/status", summary="Get YOLOv8 model loading status and config")
async def get_model_status():
    """
    Returns current status and metadata of the YOLOv8 model service.
    """
    return yolo_service.get_model_info()


@router.post("/reload", summary="Reload YOLOv8 model weights")
async def reload_model():
    """
    Triggers reloading of the YOLOv8 model from the configured path.
    """
    success = yolo_service.load_model()
    return {
        "success": success,
        "status": yolo_service.get_model_info(),
    }
