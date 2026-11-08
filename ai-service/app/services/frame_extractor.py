import logging
import os
from dataclasses import dataclass
from typing import Generator, Optional, Tuple

logger = logging.getLogger(__name__)


@dataclass
class VideoMetadata:
    total_frames: int
    fps: float
    duration_seconds: float
    width: int
    height: int
    codec: str = "unknown"

    def to_dict(self) -> dict:
        return {
            "total_frames": self.total_frames,
            "fps": round(self.fps, 2),
            "duration_seconds": round(self.duration_seconds, 2),
            "width": self.width,
            "height": self.height,
            "codec": self.codec,
        }


@dataclass
class ExtractedFrame:
    frame_index: int
    timestamp_ms: float
    frame: any  # numpy.ndarray


class FrameExtractor:
    """
    OpenCV-based frame extraction pipeline designed for video analysis and fish tracking.
    Extracts frames either sequentially or sampled at a target frame rate (FPS).
    """

    def __init__(self, default_target_fps: float = 2.0, max_frames: int = 600):
        self.default_target_fps = default_target_fps
        self.max_frames = max_frames

    def get_metadata(self, video_path: str) -> VideoMetadata:
        """
        Reads video file header and properties using OpenCV.
        """
        if not os.path.exists(video_path):
            raise FileNotFoundError(f"Video file not found at path: {video_path}")

        try:
            import cv2
        except ImportError:
            raise RuntimeError("OpenCV (cv2) is not installed.")

        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise ValueError(f"Could not open video file: {video_path}")

        try:
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            fps = float(cap.get(cv2.CAP_PROP_FPS))
            if fps <= 0:
                fps = 30.0  # Fallback standard FPS if metadata is missing or zero

            width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            fourcc = int(cap.get(cv2.CAP_PROP_FOURCC))
            codec = "".join([chr((fourcc >> 8 * i) & 0xFF) for i in range(4)]).strip()

            duration_seconds = total_frames / fps if fps > 0 else 0.0

            return VideoMetadata(
                total_frames=total_frames,
                fps=fps,
                duration_seconds=duration_seconds,
                width=width,
                height=height,
                codec=codec or "unknown",
            )
        finally:
            cap.release()

    def extract_frames(
        self,
        video_path: str,
        target_fps: Optional[float] = None,
        max_frames: Optional[int] = None,
        resize_dim: Optional[Tuple[int, int]] = None,
    ) -> Generator[ExtractedFrame, None, None]:
        """
        Generator that yields ExtractedFrame instances sampled at target_fps.
        Using a generator keeps memory usage minimal for large videos.
        """
        if not os.path.exists(video_path):
            raise FileNotFoundError(f"Video file not found: {video_path}")

        try:
            import cv2
        except ImportError:
            raise RuntimeError("OpenCV (cv2) is not installed.")

        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise ValueError(f"Could not open video file: {video_path}")

        effective_target_fps = target_fps or self.default_target_fps
        limit_frames = max_frames or self.max_frames

        fps = float(cap.get(cv2.CAP_PROP_FPS))
        if fps <= 0:
            fps = 30.0

        # Calculate sample interval (e.g. if original is 30fps and target is 2fps -> step is 15 frames)
        step = max(1, int(round(fps / effective_target_fps)))

        current_frame_idx = 0
        yielded_count = 0

        try:
            while cap.isOpened() and yielded_count < limit_frames:
                ret, frame = cap.read()
                if not ret or frame is None:
                    break

                if current_frame_idx % step == 0:
                    timestamp_ms = (current_frame_idx / fps) * 1000.0

                    if resize_dim:
                        frame = cv2.resize(frame, resize_dim)

                    yield ExtractedFrame(
                        frame_index=current_frame_idx,
                        timestamp_ms=timestamp_ms,
                        frame=frame,
                    )
                    yielded_count += 1

                current_frame_idx += 1
        finally:
            cap.release()
            logger.info(
                f"Frame extraction completed for {video_path}: "
                f"yielded {yielded_count} frames from {current_frame_idx} total."
            )

    @staticmethod
    def save_frame_to_disk(frame_array, destination_path: str) -> str:
        """
        Saves a single numpy frame to an image file (e.g. JPG or PNG).
        """
        import cv2
        os.makedirs(os.path.dirname(destination_path), exist_ok=True)
        cv2.imwrite(destination_path, frame_array)
        return destination_path


# Global instance
frame_extractor = FrameExtractor()
