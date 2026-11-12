# AquaTrade Core Backend

Java 21 / Spring Boot 3.1.5 REST service for the AquaTrade marketplace.

## Capabilities

- JWT access/refresh sessions and buyer, seller and administrator roles.
- Listings, checkout, wallet transactions, escrow settlement and disputes.
- Per-order, multi-batch AI proofs with separate buyer/seller totals.
- Internal AI callbacks protected by `X-Internal-Secret`.
- Order, AI and chat events published to Redis after database commit.
- Cloudinary upload signatures and media integration.

## Requirements

Java 21, Maven, PostgreSQL, and Redis for realtime delivery. AI inference is provided by a separate Python service and is not included in this module.

Create the `aquatrade_db` database and set credentials in the terminal running the service:

```powershell
$env:DATABASE_URL = 'jdbc:postgresql://localhost:5432/aquatrade_db'
$env:DATABASE_USERNAME = 'postgres'
$env:DATABASE_PASSWORD = '<your-local-database-password>'
$env:JWT_SECRET = '<random-signing-secret-at-least-32-bytes>'
$env:INTERNAL_API_KEY = '<shared-internal-service-secret>'
$env:APP_BASEURL = 'http://localhost:8080'
$env:AI_SERVICE_URL = 'http://localhost:8000/ai/v1/jobs'
$env:AQUATRADE_REALTIME_PUBLISH_ENABLED = 'true'
$env:REDIS_HOST = 'localhost'
$env:REDIS_PORT = '6379'
mvn spring-boot:run
```

Set `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY` and `CLOUDINARY_API_SECRET` for signed media uploads. The AI service must send the same internal secret when calling Core. Its successful callback implementation must use the configured value as well.

The API base URL is `http://localhost:8080/api/v1`. Android Emulator clients use `http://10.0.2.2:8080/api/v1`.

## Tests

```powershell
mvn test
```

Tests use H2 and synthetic signing/internal secrets in `application-test.properties`. A cached Maven installation can run them with `mvn -o test`.

## Demo behavior

This code retains the current academic demo workflows. `DataInitializer` is disabled by default. To seed demo accounts, explicitly set `DEMO_SEED_ENABLED=true` and provide non-empty `DEMO_ADMIN_PASSWORD`, `DEMO_SELLER_PASSWORD`, and `DEMO_BUYER_PASSWORD`. When enabled, initialization can reset demo account passwords and selected balances on startup. Passwords are never written to logs. Database repair components also alter order-status constraints. Review these behaviors before using an existing non-demo database.

Uploaded media, local keystores, database passwords and service credentials are excluded from the repository. Provide secrets through the environment; `.env` files are not loaded automatically by Spring Boot.
