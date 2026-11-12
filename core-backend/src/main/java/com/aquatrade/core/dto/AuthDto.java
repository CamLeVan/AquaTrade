package com.aquatrade.core.dto;

import com.aquatrade.core.domain.enums.Role;
import lombok.Data;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class AuthDto {
    @Data
    public static class LoginRequest {
        @Email(message = "Email không hợp lệ") 
        @NotBlank(message = "Email không được để trống")
        private String email;
        
        @NotBlank(message = "Mật khẩu không được để trống")
        private String password;
        
        private Boolean rememberMe;
    }

    @Data
    public static class RegisterRequest {
        @NotBlank(message = "Tên không được để trống")
        private String fullName;
        
        private String companyName;
        
        @Email(message = "Email không hợp lệ") 
        @NotBlank(message = "Email không được để trống")
        private String email;
        
        @NotBlank(message = "Mật khẩu không được để trống")
        private String password;
        
        @NotNull(message = "Phân quyền không được để trống")
        private Role role;
    }

    @Data
    public static class AuthResponse {
        private String token; // Access Token
        private String refreshToken; // Refresh Token
        private Role role;
        private String userId;
    }

    @Data
    public static class RefreshRequest {
        @NotBlank(message = "Refresh Token không được để trống")
        private String refreshToken;
    }
}
