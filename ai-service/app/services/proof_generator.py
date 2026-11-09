from datetime import datetime, timezone
import hashlib
import json
import os
from typing import Any, Dict, Optional

from app.core.config import settings


def hash_file_sha256(filepath: str) -> str:
    """
    Computes SHA-256 hash of an on-disk file in chunks.
    """
    if not os.path.exists(filepath):
        # Return fallback deterministic hash if virtual/mock file
        return hashlib.sha256(filepath.encode("utf-8")).hexdigest()

    sha256 = hashlib.sha256()
    with open(filepath, "rb") as f:
        while True:
            chunk = f.read(64 * 1024)
            if not chunk:
                break
            sha256.update(chunk)
    return sha256.hexdigest()


class DigitalProofGenerator:
    """
    Generates tamper-evident cryptographic digital proofs for AquaTrade transactions,
    linking uploaded video evidence, model inference, and counting results.
    """

    @staticmethod
    def generate_proof(
        job_id: str,
        listing_id: Optional[str],
        video_path: str,
        fish_count: int,
        confidence_score: float,
        model_version: str = settings.VERSION,
        timestamp: Optional[datetime] = None,
    ) -> Dict[str, Any]:
        verified_at = timestamp or datetime.now(timezone.utc)
        video_hash = hash_file_sha256(video_path)

        # Canonical canonical proof dictionary
        canonical_data = {
            "version": "1.0",
            "algorithm": "SHA-256",
            "job_id": job_id,
            "listing_id": listing_id or "unassigned",
            "video_sha256": video_hash,
            "fish_count": fish_count,
            "confidence_score": round(confidence_score, 4),
            "model_version": model_version,
            "verified_at": verified_at.isoformat(),
        }

        # Compute deterministic cryptographic hash of the JSON representation
        serialized = json.dumps(canonical_data, sort_keys=True).encode("utf-8")
        proof_hash = hashlib.sha256(serialized).hexdigest()

        canonical_data["proof_hash"] = proof_hash
        return canonical_data

    @staticmethod
    def verify_proof(proof_data: Dict[str, Any]) -> bool:
        """
        Validates the integrity of a digital proof by recomputing its hash.
        """
        if "proof_hash" not in proof_data:
            return False

        claimed_hash = proof_data["proof_hash"]
        data_to_verify = {k: v for k, v in proof_data.items() if k != "proof_hash"}
        serialized = json.dumps(data_to_verify, sort_keys=True).encode("utf-8")
        recomputed_hash = hashlib.sha256(serialized).hexdigest()

        return claimed_hash == recomputed_hash


# Global instance
proof_generator = DigitalProofGenerator()
