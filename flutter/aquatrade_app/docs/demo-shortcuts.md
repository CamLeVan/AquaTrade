# Demo shortcuts (tạm — revert khi chốt production)

Hai thay đổi BE để test luồng mua/bán nhanh, **không** dùng cho production:

| Việc | File | Hành vi demo | Production (cũ) |
|---|---|---|---|
| Đăng tin | `ListingServiceImpl.createListing` | `AVAILABLE` ngay → lên Chợ | `PENDING_REVIEW` |
| Nạp tiền | `WalletServiceImpl.deposit` | Cộng `walletBalance` + tx `SUCCESS` ngay | tx `PENDING`, Admin `approveDeposit` |

Flutter copy đã chỉnh: create-listing snackbar + topup `pending=0` + refresh wallet.

**Restart core-backend** sau khi sửa rồi mới test.
