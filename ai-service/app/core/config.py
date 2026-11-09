from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "AquaTrade AI Service"
    VERSION: str = "0.2.0"
    DESCRIPTION: str = "AI inference and digital proof verification service for AquaTrade"
    API_V1_STR: str = "/api/v1"
    
    # Server configuration
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    CORS_ORIGINS: List[str] = ["*"]
    
    # Model configuration
    MODEL_PATH: str = "weights/yolov8n.pt"
    MODEL_DEVICE: str = "cpu"
    CONF_THRESHOLD: float = 0.25
    IOU_THRESHOLD: float = 0.45
    
    # Storage paths
    UPLOAD_DIR: str = "uploads"
    OUTPUT_DIR: str = "output"

    # Video upload validation settings
    MAX_UPLOAD_SIZE_MB: int = 100
    ALLOWED_VIDEO_EXTENSIONS: List[str] = [".mp4", ".avi", ".mov", ".mkv", ".webm"]
    ALLOWED_VIDEO_CONTENT_TYPES: List[str] = [
        "video/mp4",
        "video/x-msvideo",
        "video/quicktime",
        "video/x-matroska",
        "video/webm",
    ]

    # Backend webhook callback settings
    BACKEND_CALLBACK_URL: str = "http://localhost:8080/api/v1/ai/proof/callback"
    CALLBACK_MAX_RETRIES: int = 3
    CALLBACK_TIMEOUT_SECONDS: float = 10.0


    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
    )


settings = Settings()
