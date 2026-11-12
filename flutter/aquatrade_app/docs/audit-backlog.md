# Audit UI ↔ BE — backlog còn lại

Cập nhật sau khi: auth session + AuthGate/Sheet, dọn `lib/src/`, sửa vài gap A (badge giỏ/đơn, order history không fallback mock khi đã login).

Audit gốc (canvas **ui-be-contract-audit**, ~Jul 28): phân loại **A** = mapping/FE, **B** = thiếu/sai logic BE.

---

## Đã xong gần đây

| Hạng mục | Ghi chú |
|---|---|
| Xóa `lib/src/` | Code chết trùng repository/model |
| Cart badge Home/Chợ | `CartProvider.totalItemCount` (không hardcode 3) |
| Badge đơn Account | `OrderProvider.orders.length` |
| Order history | Đã login → chỉ API, không mock giả |
| Wallet path | `GET/POST /users/me/wallet` (+ deposit) |
| Withdraw repo | Không gọi API ảo — `UnsupportedError` (UI snackbar) |
| Auth guest Plan B | Splash + AuthGateView + sheet — xem `auth-session-guest-access.md` |

---

## Gap A còn lại (FE, làm khi rảnh / trước demo)

| Việc | Ghi chú |
|---|---|
| Market fallback `_mockProducts` | Chỉ khi BE trống — chấp nhận demo; hoặc empty state thật |
| Checkout copy vs BE fees | Ship/AI hardcode BE (`50k+25k`/item) vs UI ước tính — chỉnh copy khi rảnh |
| Success nhiều `orderId` | **Đã chốt:** 1 listing = 1 Order → success phải hiện / nhận list ID |
| Dashboard activity mock | Home “hoạt động gần đây” vẫn mock |

---

## Quyết định đã chốt

| Việc | Quyết định | Ngày |
|---|---|---|
| Tách đơn checkout | **Giữ BE hiện tại: 1 cart item / listing = 1 Order** (VD 3 SP → 3 đơn). Không gộp theo seller. | 2026-07-31 |

FE: UI có thể vẫn nhóm theo seller để xem, nhưng thanh toán tạo N đơn — copy/success nên phản ánh đúng.

---

## Gap B — chờ team / BE

| Việc | Loại | Ghi chú |
|---|---|---|
| ~~Checkout gộp theo seller~~ | ~~B~~ | **Không làm** — đã chốt 1 listing = 1 Order |
| Phí ship/AI breakdown | B | Hardcode trong BE |
| `SellerStatus` riêng | B | FE tạm `canSell = role == SELLER` |
| Withdraw API | B | UI đã chặn |
| Cart server | B | Cart local OK demo |
| Home summary Buyer | B nhẹ | Ghép wallet+listings hoặc endpoint mới |
| Chat | B | Placeholder + AuthGate |
| AI scan Phase A (hub + video theo đơn) | A | **Đã có** hub + Cloudinary + start-ai + poll; Quét nhanh Phase B chưa |

---

## Thứ tự đề xuất tiếp

1. Checkout polish nhỏ (copy đúng “N đơn”, success list ID, đồng bộ phí nếu cần)  
2. Dashboard Buyer (ghép API lẻ nếu chưa có summary)  
3. Chat/AI / pending-action login — để sau  

Khi BE đổi contract: cập nhật bảng này + canvas audit nếu cần.
