import pytest
from app.services.tracker import FishTracker, calculate_centroid, calculate_iou


def test_iou_calculation():
    boxA = (0, 0, 10, 10)
    boxB = (0, 0, 10, 10)
    assert calculate_iou(boxA, boxB) == 1.0

    boxC = (10, 10, 20, 20)
    assert calculate_iou(boxA, boxC) == 0.0

    boxD = (5, 0, 15, 10)
    assert 0.0 < calculate_iou(boxA, boxD) < 1.0


def test_centroid_calculation():
    box = (10, 20, 30, 40)
    cx, cy = calculate_centroid(box)
    assert cx == 20
    assert cy == 30


def test_fish_tracker_prevents_duplicate_counting():
    tracker = FishTracker(max_disappeared=10, max_distance=50.0)

    # Frame 1: 2 distinct fish
    detections_f1 = [
        {"bbox": [50, 50, 100, 100], "confidence": 0.9},
        {"bbox": [200, 200, 250, 250], "confidence": 0.85},
    ]
    active_1 = tracker.update(detections_f1, frame_idx=1)
    assert len(active_1) == 2
    assert tracker.get_unique_fish_count() == 2

    # Frame 2: Same 2 fish moving slightly by 5 pixels
    detections_f2 = [
        {"bbox": [55, 52, 105, 102], "confidence": 0.91},
        {"bbox": [203, 198, 253, 248], "confidence": 0.87},
    ]
    active_2 = tracker.update(detections_f2, frame_idx=2)
    assert len(active_2) == 2
    # Count should STILL be 2, NOT 4!
    assert tracker.get_unique_fish_count() == 2

    # Frame 3: One new fish enters the frame
    detections_f3 = [
        {"bbox": [58, 54, 108, 104], "confidence": 0.92},
        {"bbox": [205, 195, 255, 245], "confidence": 0.88},
        {"bbox": [400, 400, 460, 460], "confidence": 0.95},  # New fish
    ]
    active_3 = tracker.update(detections_f3, frame_idx=3)
    assert len(active_3) == 3
    # Total unique count should now be 3
    assert tracker.get_unique_fish_count() == 3


def test_fish_tracker_deregistration():
    tracker = FishTracker(max_disappeared=3)
    detections = [{"bbox": [50, 50, 100, 100], "confidence": 0.9}]
    tracker.update(detections, frame_idx=1)
    assert len(tracker.active_tracks) == 1

    # Disappear for 4 frames
    for f in range(2, 6):
        tracker.update([], frame_idx=f)

    # Should be deregistered from active tracks
    assert len(tracker.active_tracks) == 0
    # But total unique fish counted remains 1
    assert tracker.get_unique_fish_count() == 1
