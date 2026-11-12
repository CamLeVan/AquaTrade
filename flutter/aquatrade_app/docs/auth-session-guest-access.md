# Auth session + guest access (Plan B)

Tài liệu mô tả **xác thực phiên** và **cách mời đăng nhập tại chỗ** (không redirect cứng). Guest duyệt Home + Chợ + chi tiết sản phẩm; các màn/hành động cần login hiện UI khoá hoặc bottom sheet; sau login quay đúng URL.

---

## Quyết định sản phẩm

| Phương án | Hành vi | Kết luận |
|---|---|---|
| **A** | Bắt login ngay từ Splash | Không chọn |
| **B** | Guest xem trước, hành động / màn nhạy cảm mới auth | **Đã chọn** |

### Hai hướng UI (đã triển khai)

| Hướng | Khi nào | Widget |
|---|---|---|
| **H2 — trang khoá** | Guest vào đúng URL tab/màn (`/account`, `/chat`, `/wallet`…) | `AuthGateView` (EmptyState + Đăng nhập / Đăng ký) |
| **H1 — bottom sheet** | Hành động giữa luồng (thêm giỏ, đàm phán, …) | `AuthRequiredSheet` qua `goLoginRequired` |

**Không** tự thực hiện lại hành động sau login (guest phải bấm lại) — đơn giản cho đồ án; có thể nâng cấp pending-action sau.

---

## Kiến trúc phiên

### `SessionStatus`

```text
unknown  →  authenticated
         →  unauthenticated
```

- `unknown`: Splash — chưa quyết định Home.
- `authenticated`: token OK + `GET /users/me`.
- `unauthenticated`: không token / profile fail / refresh fail.

### Bootstrap

1. `GoRouter` `initialLocation` = `/splash`, `refreshListenable: auth`.
2. `restoreSession()` sau first frame.
3. `ApiService.onSessionExpired` → `handleSessionExpired` (chỉ khi **đã** từng authenticated; bỏ qua nếu đã `unauthenticated`).

**File:** `auth_provider.dart`, `splash_screen.dart`, `main.dart`, `api_service.dart`

### Redirect (chỉ còn 2 việc)

1. `unknown` → `/splash`
2. Đã login mà đứng Login/Register → `?from=` hoặc Home

**Không** còn `_requiresAuth` đẩy guest sang `/login`. Guest vào được URL; màn tự render `AuthGateView`.

---

## Ma trận quyền

### Guest được xem

| Route / UI | Ghi chú |
|---|---|
| `/` Home | Xem trước |
| `/market` (Khám phá) | Listing AVAILABLE |
| `/product`, `/product/:id` | Xem chi tiết (`GET /listings/**` permitAll) |
| `/login`, `/register`, `/splash` | Auth / bootstrap |

### Guest vào được URL nhưng thấy AuthGateView (H2)

| Route | `LoginReasons` |
|---|---|
| `/account`, `/chat`, `/ai-scan` | account / chat / ai |
| `/cart`, `/checkout/*` | cart / checkout |
| `/wallet/*` | wallet |
| `/orders/*` | orders |
| `/listings/create` | listing |
| `/market` tab Gian hàng | shop |
| `/seller/*` | seller |
| `/admin/*` | generic |

### Hành động → sheet (H1), không rời ngữ cảnh

| Hành động | Reason | Sau login |
|---|---|---|
| Thêm giỏ (Chợ / Product) | `cart` | Về đúng product/market; **bấm lại** để thêm |
| Đàm phán giá | `chat` | Về product; bấm lại |

`goLoginRequired` → `showAuthRequiredSheet` (2 nút, vuốt xuống = huỷ). Không SnackBar.

---

## Quy tắc API (quan trọng)

Màn “cho vào rồi lock” **phải** `if (!isAuthenticated) return` **trước** khi gọi API (`fetchWallet`, `fetchMyOrders`, `fetchOrderById`, `fetchPendingListings`…).

Tránh: 401 thừa → tưởng session hết hạn → `handleSessionExpired` nhiễu.

Đã guard: Wallet, Topup, Orders, Order detail, Admin, Account (wallet), Cart (`loadCart` chỉ khi auth — cart local vẫn an toàn).

---

## File chính

| File | Vai trò |
|---|---|
| `lib/widgets/auth_gate_view.dart` | H2 |
| `lib/widgets/auth_required_sheet.dart` | H1 |
| `lib/features/auth/auth_navigation.dart` | `LoginReasons`, `goLoginRequired`, `goPostAuthHome` |
| `lib/core/router/app_router.dart` | Splash + post-login redirect only |
| `lib/features/shell/app_shell.dart` | Không intercept tab; AI push thẳng |

---

## Luồng tóm tắt

```text
App start → Splash → restoreSession → Home (guest hoặc user)

Guest bấm tab Account/Chat/AI
  → goBranch / push URL thật
  → AuthGateView + 2 nút → Login/Register(?from=&reason=)
  → goPostAuthHome → đứng lại đúng URL → nội dung thật

Guest bấm Thêm giỏ trên Product
  → AuthRequiredSheet
  → Login → quay Product
  → bấm lại Thêm giỏ (không auto-retry)
```

---

## Smoke test

1. Hot restart chưa login → Splash → Home.
2. Tab Tài khoản / Tin nhắn / Quét AI → trang khoá + 2 nút (không bay Login ngay).
3. Icon giỏ / Ví / Đơn → URL đúng + AuthGateView.
4. Product: xem OK; Thêm giỏ / Đàm phán → sheet; login xong về product, phải bấm lại để thêm.
5. Login seller → Account/Wallet gọi API bình thường; không 401 lúc guest.

---

## Ngoài phạm vi

- Auto-retry hành động sau login (pending action).
- UI chat / AI scan thật.
- Phân quyền buyer vs seller chi tiết trên từng màn (gate chỉ “đã login?”).
