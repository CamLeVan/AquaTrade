import logging
import os
from typing import Any, List, Optional
from app.core.config import settings

logger = logging.getLogger(__name__)


class VideoAnnotator:
    """
    Annotates video frames with detection bounding boxes, tracking ID badges,
    cumulative counts, and AquaTrade verification banners.
    """

    def __init__(self, output_dir: str = settings.OUTPUT_DIR):
        self.output_dir = output_dir
        os.makedirs(self.output_dir, exist_ok=True)

    def annotate_frame(
        self,
        frame,
        tracks: List[Any],
        total_unique_fish: int,
        frame_idx: int = 0,
    ):
        """
        Draws visual annotations onto a single OpenCV frame.
        """
        try:
            import cv2
        except ImportError:
            return frame

        h, w = frame.shape[:2]

        # 1. Draw top banner
        cv2.rectangle(frame, (0, 0), (w, 50), (20, 20, 20), -1)
        banner_text = f"AquaTrade AI Proof | Total Fish: {total_unique_fish} | Frame: #{frame_idx}"
        cv2.putText(
            frame,
            banner_text,
            (15, 32),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.75,
            (0, 255, 200),
            2,
            cv2.LINE_AA,
        )

        # 2. Draw active tracked fish
        for fish in tracks:
            bbox = fish.bbox
            x1, y1, x2, y2 = bbox

            # Bounding box
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 220, 0), 2)

            # Label badge
            label = f"Fish #{fish.track_id} ({fish.confidence:.2f})"
            (tw, th), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1)
            cv2.rectangle(
                frame,
                (x1, max(0, y1 - th - 8)),
                (x1 + tw + 6, max(th + 8, y1)),
                (0, 180, 0),
                -1,
            )
            cv2.putText(
                frame,
                label,
                (x1 + 3, max(th + 2, y1 - 4)),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.5,
                (255, 255, 255),
                1,
                cv2.LINE_AA,
            )

            # Centroid point
            cx, cy = fish.centroid
            cv2.circle(frame, (cx, cy), 4, (0, 0, 255), -1)

        # 3. Watermark at bottom right
        watermark = "VERIFIED BY AQUATRADE AI"
        cv2.putText(
            frame,
            watermark,
            (w - 240, h - 15),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.45,
            (180, 180, 180),
            1,
            cv2.LINE_AA,
        )

        return frame

    def render_annotated_video(
        self,
        job_id: str,
        frames_with_tracks: List[Any],
        fps: float = 10.0,
        frame_size: tuple = (640, 480),
    ) -> str:
        """
        Renders annotated frames to an MP4 video file.
        Returns the saved file path.
        """
        output_filename = f"{job_id}_annotated.mp4"
        output_path = os.path.join(self.output_dir, output_filename)

        try:
            import cv2
            fourcc = cv2.VideoWriter_fourcc(*"mp4v")
            writer = cv2.VideoWriter(output_path, fourcc, fps, frame_size)

            for frame in frames_with_tracks:
                if frame.shape[1] != frame_size[0] or frame.shape[0] != frame_size[1]:
                    frame = cv2.resize(frame, frame_size)
                writer.write(frame)

            writer.release()
            logger.info(f"Annotated video generated at: {output_path}")
            return output_path
        except Exception as e:
            logger.warning(f"Could not render video via OpenCV: {e}. Writing placeholder file.")
            with open(output_path, "wb") as f:
                f.write(b"MOCK_ANNOTATED_VIDEO_DATA")
            return output_path


# Global instance
video_annotator = VideoAnnotator()
