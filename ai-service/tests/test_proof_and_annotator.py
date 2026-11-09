import os
import pytest
from app.services.proof_generator import DigitalProofGenerator, hash_file_sha256
from app.services.video_annotator import VideoAnnotator


def test_proof_generation_and_integrity():
    generator = DigitalProofGenerator()
    proof = generator.generate_proof(
        job_id="job-test-proof-1",
        listing_id="listing-koi-88",
        video_path="sample_video.mp4",
        fish_count=15,
        confidence_score=0.942,
    )

    assert "proof_hash" in proof
    assert proof["fish_count"] == 15
    assert proof["algorithm"] == "SHA-256"

    # Integrity verification must pass
    assert generator.verify_proof(proof) is True

    # Tampering test: altering fish count must invalidate the proof
    tampered_proof = dict(proof)
    tampered_proof["fish_count"] = 16
    assert generator.verify_proof(tampered_proof) is False


def test_video_annotator_placeholder():
    annotator = VideoAnnotator(output_dir="output")
    out = annotator.render_annotated_video(
        job_id="test-job-render",
        frames_with_tracks=[],
    )
    assert os.path.exists(out)
    assert out.endswith("test-job-render_annotated.mp4")
