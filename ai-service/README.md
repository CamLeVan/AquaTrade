# AquaTrade AI Service

FastAPI-powered computer vision and digital proof verification microservice for AquaTrade platform.

## Features
- FastAPI asynchronous API runtime
- YOLOv8 computer vision model integration
- Asynchronous video analysis and digital proof generation

## Getting Started

### Local Setup
```bash
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Docker
```bash
docker build -t aquatrade-ai-service .
docker run -p 8000:8000 aquatrade-ai-service
```
