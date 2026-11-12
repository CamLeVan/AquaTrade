# AquaTrade Realtime Gateway

Java 21 / Spring Boot 3.3.6 gateway that routes Core Backend events from Redis Pub/Sub to WebSocket/STOMP subscribers.

## Event delivery

The default Redis channel is `aquatrade.events`. Order, AI, chat and payout events are routed to `/topic/orders/{orderId}` and the administrator order topic. Disputes are additionally routed to `/topic/admin/disputes`; user notifications target `/topic/users/{userId}/notifications`.

Core owns business state and access decisions. Redis Pub/Sub is a transient delivery mechanism; clients should reload current state from Core after reconnecting.

## Run locally

Start Redis and Core first. In the `realtime-service` directory:

```powershell
$env:AQUATRADE_REALTIME_REDIS_ENABLED = 'true'
$env:REDIS_HOST = 'localhost'
$env:REDIS_PORT = '6379'
$env:CORE_BACKEND_URL = 'http://localhost:8080'
$env:INTERNAL_API_KEY = '<same-shared-secret-as-core>'
$env:AQUATRADE_REALTIME_CORE_ACCESS_ENABLED = 'true'
mvn spring-boot:run
```

- Native WebSocket: `ws://localhost:8090/ws`.
- SockJS: `http://localhost:8090/ws-sockjs`.
- Health: `http://localhost:8090/actuator/health`.
- Android Emulator WebSocket: `ws://10.0.2.2:8090/ws`.

The current demo defaults leave STOMP authentication and subscription guarding disabled. To enforce them, set `AQUATRADE_REALTIME_AUTH_ENABLED=true`, `AQUATRADE_REALTIME_SUBSCRIPTION_GUARD_ENABLED=true` and `JWT_SECRET` to the same value used by Core. Clients must attach their bearer token to STOMP CONNECT. With guarding enabled, order subscriptions are checked against Core, user notifications are restricted to their owner, and administrator topics require the admin role.

## Tests

```powershell
mvn test
```

The smoke test covers service startup, health, development-event routing and WebSocket delivery. It does not substitute for authorization or reconnect tests against a running deployment. The included static realtime test page and development event endpoints are demo/debugging facilities.
