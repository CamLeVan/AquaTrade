import asyncio
from datetime import datetime, timezone
import logging
from typing import Any, Dict, Optional
import httpx

from app.core.config import settings
from app.schemas.job import JobResponse, JobStatus

logger = logging.getLogger(__name__)


class CallbackService:
    """
    HTTP Webhook callback client responsible for dispatching analysis results
    and cryptographic digital proofs to the AquaTrade Spring Boot backend.
    """

    def __init__(
        self,
        default_callback_url: str = settings.BACKEND_CALLBACK_URL,
        max_retries: int = settings.CALLBACK_MAX_RETRIES,
        timeout: float = settings.CALLBACK_TIMEOUT_SECONDS,
    ):
        self.default_callback_url = default_callback_url
        self.max_retries = max_retries
        self.timeout = timeout

    @staticmethod
    def build_payload(job: JobResponse) -> Dict[str, Any]:
        """
        Structures canonical JSON callback payload expected by backend Escrow/Proof service.
        """
        payload = {
            "job_id": job.job_id,
            "listing_id": job.listing_id,
            "status": job.status.value,
            "completed_at": job.completed_at.isoformat() if job.completed_at else datetime.now(timezone.utc).isoformat(),
            "error": job.error,
        }

        if job.result:
            payload.update({
                "fish_count": job.result.fish_count,
                "confidence_score": job.result.confidence_score,
                "proof_hash": job.result.proof_hash,
                "annotated_video_url": job.result.annotated_video_url,
                "proof_manifest": job.result.proof_manifest.model_dump() if job.result.proof_manifest else None,
            })
        else:
            payload.update({
                "fish_count": 0,
                "confidence_score": 0.0,
                "proof_hash": None,
                "annotated_video_url": None,
                "proof_manifest": None,
            })

        return payload

    async def send_callback(
        self,
        job: JobResponse,
        target_url: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Asynchronously sends callback to backend with exponential backoff retries.
        """
        destination = target_url or self.default_callback_url
        if not destination:
            logger.warning(f"No callback URL configured for job '{job.job_id}'. Skipping dispatch.")
            return {"success": False, "attempts": 0, "error": "No callback URL specified"}

        payload = self.build_payload(job)
        headers = {
            "Content-Type": "application/json",
            "User-Agent": f"AquaTrade-AI-Service/{settings.VERSION}",
            "X-Proof-Signature": job.result.proof_hash if job.result and job.result.proof_hash else "",
        }

        logger.info(f"Dispatching AI callback for job '{job.job_id}' to: {destination}")

        attempt = 0
        last_error = None
        last_status_code = None

        while attempt < self.max_retries:
            attempt += 1
            try:
                async with httpx.AsyncClient(timeout=self.timeout) as client:
                    response = await client.post(destination, json=payload, headers=headers)
                    last_status_code = response.status_code

                    if 200 <= response.status_code < 300:
                        logger.info(
                            f"Callback for job '{job.job_id}' succeeded on attempt {attempt} "
                            f"(status {response.status_code})"
                        )
                        return {
                            "success": True,
                            "attempts": attempt,
                            "status_code": response.status_code,
                            "error": None,
                        }
                    else:
                        last_error = f"HTTP {response.status_code}: {response.text[:200]}"
                        logger.warning(
                            f"Callback failed on attempt {attempt}/{self.max_retries}: {last_error}"
                        )
            except Exception as e:
                last_error = str(e)
                logger.warning(
                    f"Callback connection error on attempt {attempt}/{self.max_retries}: {last_error}"
                )

            if attempt < self.max_retries:
                backoff_delay = 0.2 * (2 ** (attempt - 1))
                await asyncio.sleep(backoff_delay)

        logger.error(
            f"All {self.max_retries} callback attempts failed for job '{job.job_id}'. Error: {last_error}"
        )
        return {
            "success": False,
            "attempts": attempt,
            "status_code": last_status_code,
            "error": last_error,
        }


# Global instance
callback_service = CallbackService()
