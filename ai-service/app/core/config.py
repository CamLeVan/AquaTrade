from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "AquaTrade AI Service"
    VERSION: str = "0.1.0"
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

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
    )


settings = Settings()
