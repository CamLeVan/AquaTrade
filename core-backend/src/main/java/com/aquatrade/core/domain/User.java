package com.aquatrade.core.domain;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

import com.aquatrade.core.domain.base.BaseObject;
import com.aquatrade.core.domain.enums.Role;
import com.aquatrade.core.domain.enums.UserStatus;
import com.aquatrade.core.domain.enums.VerificationStatus;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User extends BaseObject {


    @Column(name = "email", unique = true, nullable = false)
    private String email;

    @Column(name = "username", unique = true)
    private String username;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    // === Thông tin cá nhân ===
    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(name = "phone_number")
    private String phoneNumber;

    @Column(name = "avatar_url")
    private String avatarUrl;

    // Tên công ty — chủ yếu dành cho Seller (trại giống) và Buyer (doanh nghiệp)
    @Column(name = "company_name")
    private String companyName;

    @Column(name = "address", columnDefinition = "TEXT")
    private String address;

    // === Phân quyền & Trạng thái ===
    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false)
    private Role role;


    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    @Builder.Default
    private UserStatus status = UserStatus.ACTIVE;

    @Enumerated(EnumType.STRING)
    @Column(name = "verification_status", nullable = false)
    @Builder.Default
    private VerificationStatus verificationStatus = VerificationStatus.UNVERIFIED;

    // === Ví hệ thống (Escrow) ===
    @Column(name = "wallet_balance", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal walletBalance = BigDecimal.ZERO;

    // Cơ chế Optimistic Locking chống lỗi tính sai lệch giao dịch song song cho Ví hệ thống Escrow
    @Version
    @Column(name = "version")
    private Integer version;
}
