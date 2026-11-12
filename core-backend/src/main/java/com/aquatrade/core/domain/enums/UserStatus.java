package com.aquatrade.core.domain.enums;

/**
 * Trạng thái tài khoản người dùng.
 * ACTIVE   = Tài khoản hoạt động bình thường.
 * INACTIVE = Tài khoản bị khóa bởi Admin.
 * PENDING  = Tài khoản mới đăng ký, chờ xác minh email hoặc KYC (Seller).
 *
 * NOTE: Trạng thái "OFFLINE/ONLINE" là realtime (Socket), KHÔNG lưu DB.
 */
public enum UserStatus {
    ACTIVE,
    INACTIVE,
    PENDING
}
