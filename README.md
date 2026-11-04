# AquaTrade AI

Nền tảng thương mại điện tử cho ngành cá giống, đặt nền tảng cho các luồng
Marketplace, Escrow và xác thực số lượng cá bằng AI.

## Cấu trúc mã nguồn

```text
backend/       Spring Boot API và nghiệp vụ giao dịch
ai-service/    FastAPI cho tác vụ phân tích video/AI
frontend/      React + Vite cho giao diện Web
docker-compose.yml
```

## Chạy nhanh bằng Docker

```bash
docker compose up --build
```

Sau khi khởi động:

- Frontend: http://localhost:5173
- Backend health: http://localhost:8080/api/v1/health
- AI health: http://localhost:8000/ai/v1/health

## Chạy từng dịch vụ

Backend yêu cầu Java 21 và Maven:

```bash
cd backend
mvn spring-boot:run
```

AI service yêu cầu Python 3.11 trở lên:

```bash
cd ai-service
python -m venv .venv
.venv/Scripts/pip install -r requirements.txt
.venv/Scripts/python -m uvicorn app.main:app --reload --port 8000
```

Frontend yêu cầu Node.js 20 trở lên:

```bash
cd frontend
npm install
npm run dev
```

## Quy ước phát triển

- Không push trực tiếp vào `main`.
- Làm việc trên nhánh `feature/<phan-he>-<ten>` và tạo Pull Request vào `develop`.
- Dùng Conventional Commits, ví dụ: `feat(escrow): lock buyer balance`.
- Biến môi trường thực tế và khoá bí mật không được commit vào Git.
