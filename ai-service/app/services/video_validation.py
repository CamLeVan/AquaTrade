import os
import uuid
from typing import Dict, Any, Tuple
from fastapi import UploadFile, HTTPException, status

from app.core.config import settings

# Recognized video magic headers
VIDEO_MAGIC_SIGNATURES = [
    (4, b"ftyp"),          # MP4 / M4V / QuickTime
    (4, b"moov"),          # QuickTime
    (0, b"RIFF"),          # AVI (starts with RIFF, followed by AVI)
    (0, b"\x1a\x45\xdf\xa3"),  # MKV / WebM EBML header
]


def validate_magic_bytes(header_bytes: bytes) -> bool:
    """
    Checks if initial bytes contain known video signatures.
    """
    if len(header_bytes) < 8:
        return False

    for offset, signature in VIDEO_MAGIC_SIGNATURES:
        if header_bytes[offset: offset + len(signature)] == signature:
            return True

    return False


async def validate_video_file(
    file: UploadFile,
    max_size_mb: int = settings.MAX_UPLOAD_SIZE_MB,
) -> Dict[str, Any]:
    """
    Validates uploaded video file against extension, MIME type, size, and header signature.
    """
    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Filename is missing.",
        )

    # 1. Validate file extension
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in settings.ALLOWED_VIDEO_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Unsupported video extension '{ext}'. "
                f"Allowed extensions: {', '.join(settings.ALLOWED_VIDEO_EXTENSIONS)}"
            ),
        )

    # 2. Validate MIME content-type
    content_type = file.content_type or ""
    if content_type not in settings.ALLOWED_VIDEO_CONTENT_TYPES and not content_type.startswith("video/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid video Content-Type '{content_type}'. Must be a valid video MIME type.",
        )

    # 3. Read initial chunk to inspect magic bytes and measure size
    header = await file.read(64)
    if not header:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty (0 bytes).",
        )

    if not validate_magic_bytes(header):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File content does not match recognized video binary format signatures.",
        )

    # 4. Measure total size and enforce limit
    # Reset pointer to start so subsequent reads get the full file
    await file.seek(0)
    
    # Check size by reading chunks
    total_size = 0
    max_bytes = max_size_mb * 1024 * 1024
    chunk_size = 1024 * 1024  # 1MB chunks

    while True:
        chunk = await file.read(chunk_size)
        if not chunk:
            break
        total_size += len(chunk)
        if total_size > max_bytes:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"Video file exceeds maximum allowable size of {max_size_mb} MB.",
            )

    # Reset seek pointer again for storage saving
    await file.seek(0)

    return {
        "filename": file.filename,
        "extension": ext,
        "content_type": content_type,
        "size_bytes": total_size,
    }


async def save_uploaded_video(
    file: UploadFile,
    upload_dir: str = settings.UPLOAD_DIR,
) -> Tuple[str, int]:
    """
    Saves an uploaded video to disk securely using a UUID-generated filename.
    Returns (saved_file_path, total_size_bytes).
    """
    os.makedirs(upload_dir, exist_ok=True)

    ext = os.path.splitext(file.filename or "")[1].lower()
    unique_filename = f"{uuid.uuid4().hex}{ext}"
    dest_path = os.path.join(upload_dir, unique_filename)

    total_bytes = 0
    await file.seek(0)
    with open(dest_path, "wb") as f:
        while True:
            chunk = await file.read(1024 * 1024)
            if not chunk:
                break
            f.write(chunk)
            total_bytes += len(chunk)

    return dest_path, total_bytes
