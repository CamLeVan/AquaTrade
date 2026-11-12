package com.aquatrade.core.service.impl;

import com.aquatrade.core.domain.User;
import com.aquatrade.core.domain.enums.UserStatus;
import com.aquatrade.core.dto.AuthDto;
import com.aquatrade.core.repository.UserRepository;
import com.aquatrade.core.security.JwtProvider;
import com.aquatrade.core.service.AuthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import com.aquatrade.core.domain.RefreshToken;
import com.aquatrade.core.repository.RefreshTokenRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtProvider jwtProvider;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public AuthDto.AuthResponse login(AuthDto.LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Email không chính xác"));

        // BCrypt verify password
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Mật khẩu không chính xác");
        }

        boolean rememberMe = request.getRememberMe() != null && request.getRememberMe();
        
        // 1. Tạo JWT siêu ngắn (15 phút)
        String accessToken = jwtProvider.generateAccessToken(user.getId(), user.getRole().name());

        // 2. Tạo Refresh Token lưu DB (Opaque token)
        RefreshToken refreshToken = createRefreshToken(user, rememberMe);

        log.info("User đăng nhập thành công: {}", user.getEmail());

        AuthDto.AuthResponse response = new AuthDto.AuthResponse();
        response.setToken(accessToken);
        response.setRefreshToken(refreshToken.getToken());
        response.setRole(user.getRole());
        response.setUserId(user.getId().toString());
        return response;
    }

    @Override
    @Transactional
    public AuthDto.AuthResponse register(AuthDto.RegisterRequest request) {
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new IllegalArgumentException("Email đã tồn tại trong hệ thống");
        }

        // Prevent Mass Assignment: User cannot register as ADMIN
        com.aquatrade.core.domain.enums.Role role = request.getRole();
        if (role == com.aquatrade.core.domain.enums.Role.ADMIN) {
            throw new IllegalArgumentException("Không thể đăng ký với quyền ADMIN");
        }

        // BCrypt encrypt password
        User newUser = User.builder()
                .fullName(request.getFullName())
                .companyName(request.getCompanyName())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(role)
                .status(UserStatus.ACTIVE)
                .walletBalance(BigDecimal.ZERO)
                .build();

        userRepository.save(newUser);
        log.info("User đăng ký thành công: {} - Role: {}", newUser.getEmail(), newUser.getRole());

        String accessToken = jwtProvider.generateAccessToken(newUser.getId(), newUser.getRole().name());
        RefreshToken refreshToken = createRefreshToken(newUser, false);

        AuthDto.AuthResponse response = new AuthDto.AuthResponse();
        response.setToken(accessToken);
        response.setRefreshToken(refreshToken.getToken());
        response.setRole(newUser.getRole());
        response.setUserId(newUser.getId().toString());
        return response;
    }

    private RefreshToken createRefreshToken(User user, boolean rememberMe) {
        long days = rememberMe ? 30 : 1;
        // Upsert logic: Update nếu đã có token, hoặc Create nếu chưa có. Không Delete để tránh lỗi Queue.
        RefreshToken refreshToken = refreshTokenRepository.findByUserId(user.getId())
                .orElse(RefreshToken.builder().user(user).build());

        refreshToken.setToken(UUID.randomUUID().toString());
        refreshToken.setExpiryDate(LocalDateTime.now().plusDays(days));
        return refreshTokenRepository.save(refreshToken);
    }

    @Override
    @Transactional
    public AuthDto.AuthResponse refreshToken(AuthDto.RefreshRequest request) {
        RefreshToken validToken = refreshTokenRepository.findByToken(request.getRefreshToken())
                .orElseThrow(() -> new IllegalArgumentException("Refresh Token không hợp lệ."));

        if (validToken.getExpiryDate().isBefore(LocalDateTime.now())) {
            refreshTokenRepository.delete(validToken);
            throw new IllegalArgumentException("Refresh Token đã hết hạn. Vui lòng đăng nhập lại.");
        }

        User user = validToken.getUser();
        
        // Cấp Access Token mới
        String newAccessToken = jwtProvider.generateAccessToken(user.getId(), user.getRole().name());

        // Token Rotation: Cấp luôn Refresh Token mới + Xoá cái cũ
        refreshTokenRepository.delete(validToken);
        RefreshToken newRefreshToken = createRefreshToken(user, true); // Giả định tiếp tục gia hạn thiết bị này

        AuthDto.AuthResponse response = new AuthDto.AuthResponse();
        response.setToken(newAccessToken);
        response.setRefreshToken(newRefreshToken.getToken());
        response.setRole(user.getRole());
        response.setUserId(user.getId().toString());
        return response;
    }

    @Override
    @Transactional
    public void logout(UUID userId) {
        // Thu hồi toàn bộ Refresh Token của User này
        refreshTokenRepository.deleteByUserId(userId);
    }
}
