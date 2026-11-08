import os
import pytest
from app.services.frame_extractor import FrameExtractor, VideoMetadata


def test_frame_extractor_file_not_found():
    extractor = FrameExtractor()
    with pytest.raises(FileNotFoundError):
        extractor.get_metadata("non_existent_video.mp4")

    with pytest.raises(FileNotFoundError):
        list(extractor.extract_frames("non_existent_video.mp4"))


def test_video_metadata_dataclass():
    meta = VideoMetadata(
        total_frames=300,
        fps=30.0,
        duration_seconds=10.0,
        width=1920,
        height=1080,
        codec="avc1",
    )
    d = meta.to_dict()
    assert d["total_frames"] == 300
    assert d["fps"] == 30.0
    assert d["duration_seconds"] == 10.0
    assert d["width"] == 1920
    assert d["height"] == 1080
    assert d["codec"] == "avc1"
