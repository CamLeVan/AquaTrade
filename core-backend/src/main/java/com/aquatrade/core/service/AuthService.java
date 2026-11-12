package com.aquatrade.core.service;

import com.aquatrade.core.dto.AuthDto;
import java.util.UUID;

public interface AuthService {
    AuthDto.AuthResponse login(AuthDto.LoginRequest request);
    AuthDto.AuthResponse register(AuthDto.RegisterRequest request);
    AuthDto.AuthResponse refreshToken(AuthDto.RefreshRequest request);
    void logout(UUID userId);
}
