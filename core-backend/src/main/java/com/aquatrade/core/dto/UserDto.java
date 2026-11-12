package com.aquatrade.core.dto;

import com.aquatrade.core.domain.enums.Role;
import com.aquatrade.core.domain.enums.UserStatus;
import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class UserDto {
    private String id;
    private String fullName;
    private String email;
    private String username;
    private String phoneNumber;
    private String avatarUrl;
    private String companyName;
    private String address;
    private Role role;
    private UserStatus status;
    private com.aquatrade.core.domain.enums.VerificationStatus verificationStatus;
    private java.math.BigDecimal walletBalance;
    private LocalDateTime createdAt;
}
