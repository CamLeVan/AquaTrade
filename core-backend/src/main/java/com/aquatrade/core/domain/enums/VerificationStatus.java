package com.aquatrade.core.domain.enums;

/**
 * Trạng thái xác thực tài khoản.
 * UNVERIFIED = Người dùng mới, chưa gửi yêu cầu xác thực.
 * PENDING    = Đang chờ Admin duyệt yêu cầu xác thực.
 * VERIFIED   = Đã được Admin xác thực.
 */
public enum VerificationStatus {
    UNVERIFIED,
    PENDING,
    VERIFIED
}
