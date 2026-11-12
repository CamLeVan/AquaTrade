package com.aquatrade.core.dto;

import lombok.Builder;
import lombok.Data;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/**
 * DTO form liên hệ / phản hồi — Contact page.
 * 🔜 Lưu vào bảng `contact_requests` hoặc gửi email trực tiếp.
 */
@Data
@Builder
public class ContactRequestDto {
    @NotBlank
    private String fullName;

    @Email @NotBlank
    private String email;

    @NotBlank
    private String subject;

    @NotBlank
    private String message;
}
