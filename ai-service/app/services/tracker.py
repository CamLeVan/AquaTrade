import math
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple


@dataclass
class TrackedFish:
    track_id: int
    bbox: Tuple[int, int, int, int]  # (x1, y1, x2, y2)
    centroid: Tuple[int, int]         # (cx, cy)
    confidence: float
    first_seen_frame: int
    last_seen_frame: int
    disappeared_frames: int = 0
    total_detections: int = 1


def calculate_iou(boxA: Tuple[int, int, int, int], boxB: Tuple[int, int, int, int]) -> float:
    """
    Computes Intersection over Union (IoU) between two bounding boxes.
    """
    xA = max(boxA[0], boxB[0])
    yA = max(boxA[1], boxB[1])
    xB = min(boxA[2], boxB[2])
    yB = min(boxA[3], boxB[3])

    inter_width = max(0, xB - xA)
    inter_height = max(0, yB - yA)
    inter_area = inter_width * inter_height

    boxA_area = max(0, boxA[2] - boxA[0]) * max(0, boxA[3] - boxA[1])
    boxB_area = max(0, boxB[2] - boxB[0]) * max(0, boxB[3] - boxB[1])
    union_area = float(boxA_area + boxB_area - inter_area)

    return inter_area / union_area if union_area > 0 else 0.0


def calculate_centroid(bbox: Tuple[int, int, int, int]) -> Tuple[int, int]:
    """
    Calculates (cx, cy) center coordinate of a bounding box.
    """
    cx = int((bbox[0] + bbox[2]) / 2.0)
    cy = int((bbox[1] + bbox[3]) / 2.0)
    return cx, cy


def euclidean_distance(pt1: Tuple[int, int], pt2: Tuple[int, int]) -> float:
    return math.sqrt((pt1[0] - pt2[0]) ** 2 + (pt1[1] - pt2[1]) ** 2)


class FishTracker:
    """
    Centroid and IoU multi-object tracking pipeline designed to maintain persistent
    identities for detected fish across consecutive video frames, preventing duplicate counts.
    """

    def __init__(self, max_disappeared: int = 25, max_distance: float = 120.0, iou_threshold: float = 0.25):
        self.next_track_id: int = 1
        self.active_tracks: Dict[int, TrackedFish] = {}
        self.max_disappeared: int = max_disappeared
        self.max_distance: float = max_distance
        self.iou_threshold: float = iou_threshold
        self.total_unique_fish: int = 0
        self.history_tracks: List[TrackedFish] = []

    def reset(self):
        self.next_track_id = 1
        self.active_tracks.clear()
        self.total_unique_fish = 0
        self.history_tracks.clear()

    def register(self, bbox: Tuple[int, int, int, int], confidence: float, frame_idx: int) -> TrackedFish:
        centroid = calculate_centroid(bbox)
        fish = TrackedFish(
            track_id=self.next_track_id,
            bbox=bbox,
            centroid=centroid,
            confidence=confidence,
            first_seen_frame=frame_idx,
            last_seen_frame=frame_idx,
            disappeared_frames=0,
            total_detections=1,
        )
        self.active_tracks[self.next_track_id] = fish
        self.next_track_id += 1
        self.total_unique_fish += 1
        return fish

    def deregister(self, track_id: int):
        if track_id in self.active_tracks:
            fish = self.active_tracks.pop(track_id)
            self.history_tracks.append(fish)

    def update(
        self,
        detections: List[Dict[str, Any]],
        frame_idx: int = 0,
    ) -> List[TrackedFish]:
        """
        Updates the tracker with detections from the current frame:
        detections: list of dicts with 'bbox': [x1, y1, x2, y2] and 'confidence': float
        """
        if not detections:
            # All active tracks marked as disappeared
            for track_id in list(self.active_tracks.keys()):
                self.active_tracks[track_id].disappeared_frames += 1
                if self.active_tracks[track_id].disappeared_frames > self.max_disappeared:
                    self.deregister(track_id)
            return list(self.active_tracks.values())

        input_bboxes = [tuple(d["bbox"]) for d in detections]
        input_confs = [float(d.get("confidence", 0.5)) for d in detections]
        input_centroids = [calculate_centroid(box) for box in input_bboxes]

        # If currently tracking no fish, register all new detections
        if not self.active_tracks:
            for i in range(len(input_bboxes)):
                self.register(input_bboxes[i], input_confs[i], frame_idx)
            return list(self.active_tracks.values())

        track_ids = list(self.active_tracks.keys())
        active_centroids = [self.active_tracks[tid].centroid for tid in track_ids]
        active_bboxes = [self.active_tracks[tid].bbox for tid in track_ids]

        # Calculate pairwise cost matrix (combination of centroid distance and 1 - IoU)
        matched_tracks = set()
        matched_inputs = set()

        matches = []
        for a_idx, tid in enumerate(track_ids):
            for i_idx in range(len(input_bboxes)):
                dist = euclidean_distance(active_centroids[a_idx], input_centroids[i_idx])
                iou = calculate_iou(active_bboxes[a_idx], input_bboxes[i_idx])
                
                # Check if plausible match
                if dist <= self.max_distance or iou >= self.iou_threshold:
                    matches.append((dist - (iou * 50.0), a_idx, i_idx))

        # Sort matches by cost ascending
        matches.sort(key=lambda x: x[0])

        for _, a_idx, i_idx in matches:
            tid = track_ids[a_idx]
            if tid in matched_tracks or i_idx in matched_inputs:
                continue

            # Update tracked fish
            fish = self.active_tracks[tid]
            fish.bbox = input_bboxes[i_idx]
            fish.centroid = input_centroids[i_idx]
            fish.confidence = max(fish.confidence, input_confs[i_idx])
            fish.last_seen_frame = frame_idx
            fish.disappeared_frames = 0
            fish.total_detections += 1

            matched_tracks.add(tid)
            matched_inputs.add(i_idx)

        # Handle unmatched active tracks
        for a_idx, tid in enumerate(track_ids):
            if tid not in matched_tracks:
                self.active_tracks[tid].disappeared_frames += 1
                if self.active_tracks[tid].disappeared_frames > self.max_disappeared:
                    self.deregister(tid)

        # Handle unmatched new detections -> register new fish
        for i_idx in range(len(input_bboxes)):
            if i_idx not in matched_inputs:
                self.register(input_bboxes[i_idx], input_confs[i_idx], frame_idx)

        return list(self.active_tracks.values())

    def get_unique_fish_count(self) -> int:
        return self.total_unique_fish
