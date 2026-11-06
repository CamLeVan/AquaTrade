import logging
import os
from typing import Any, Dict, Optional

from app.core.config import settings

logger = logging.getLogger(__name__)


class YOLOv8Service:
    """
    Singleton service responsible for loading, managing, and running inference
    with the YOLOv8 model for fish detection and verification.
    """

    _instance: Optional["YOLOv8Service"] = None

    def __init__(self):
        self.model: Any = None
        self.model_path: str = settings.MODEL_PATH
        self.device: str = settings.MODEL_DEVICE
        self.conf_threshold: float = settings.CONF_THRESHOLD
        self.iou_threshold: float = settings.IOU_THRESHOLD
        self._is_loaded: bool = False

    @classmethod
    def get_instance(cls) -> "YOLOv8Service":
        if cls._instance is None:
            cls._instance = YOLOv8Service()
        return cls._instance

    def load_model(self, model_path: Optional[str] = None) -> bool:
        """
        Loads the YOLOv8 model from file path or pretrained checkpoint.
        Supports graceful fallback if ultralytics or weights are unavailable in lightweight environments.
        """
        if model_path:
            self.model_path = model_path

        try:
            from ultralytics import YOLO

            logger.info(f"Loading YOLOv8 model from: {self.model_path} on device: {self.device}")
            # Ensure parent weights directory exists if specified as relative path
            weights_dir = os.path.dirname(self.model_path)
            if weights_dir and not os.path.exists(weights_dir):
                os.makedirs(weights_dir, exist_ok=True)

            self.model = YOLO(self.model_path)
            self._is_loaded = True
            logger.info("YOLOv8 model loaded successfully.")
            return True
        except ImportError:
            logger.warning(
                "Ultralytics library is not installed or importable. Running in fallback mock mode."
            )
            self._is_loaded = False
            return False
        except Exception as e:
            logger.error(f"Failed to load YOLOv8 model: {e}. Fallback enabled.")
            self._is_loaded = False
            return False

    def predict(
        self,
        source: Any,
        conf: Optional[float] = None,
        iou: Optional[float] = None,
        **kwargs,
    ) -> Any:
        """
        Runs inference on given input source (image, numpy array, or video frame).
        """
        if not self._is_loaded or self.model is None:
            logger.warning("Predict called but YOLO model is not loaded.")
            return None

        confidence = conf if conf is not None else self.conf_threshold
        iou_thresh = iou if iou is not None else self.iou_threshold

        return self.model.predict(
            source=source,
            conf=confidence,
            iou=iou_thresh,
            device=self.device,
            **kwargs,
        )

    def is_loaded(self) -> bool:
        return self._is_loaded

    def get_model_info(self) -> Dict[str, Any]:
        """
        Returns metadata about the currently configured YOLO model.
        """
        return {
            "model_type": "YOLOv8",
            "model_path": self.model_path,
            "device": self.device,
            "is_loaded": self._is_loaded,
            "conf_threshold": self.conf_threshold,
            "iou_threshold": self.iou_threshold,
        }


# Global singleton instance accessor
yolo_service = YOLOv8Service.get_instance()
