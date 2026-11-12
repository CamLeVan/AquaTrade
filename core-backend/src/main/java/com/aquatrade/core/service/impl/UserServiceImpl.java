package com.aquatrade.core.service.impl;

import com.aquatrade.core.domain.User;
import com.aquatrade.core.dto.UserDto;
import com.aquatrade.core.repository.UserRepository;
import com.aquatrade.core.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;

    @Override
    public UserDto getCurrentUser() {
        // Lấy userId từ SecurityContext (JWT Filter đã set)
        UUID userId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy user"));

        return UserDto.builder()
                .id(user.getId().toString())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .username(user.getUsername())
                .phoneNumber(user.getPhoneNumber())
                .avatarUrl(user.getAvatarUrl())
                .companyName(user.getCompanyName())
                .address(user.getAddress()) // Map address
                .role(user.getRole())
                .status(user.getStatus())
                .verificationStatus(user.getVerificationStatus())
                .walletBalance(user.getWalletBalance())
                .createdAt(user.getCreatedAt())
                .build();
    }

    @Override
    public void requestVerification() {
        UUID userId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng"));

        if (user.getVerificationStatus() == com.aquatrade.core.domain.enums.VerificationStatus.VERIFIED) {
            throw new IllegalStateException("Tài khoản của bạn đã được xác thực rồi.");
        }

        // Kiểm tra điều kiện xác thực: Cần có SĐT và Địa chỉ
        if (user.getPhoneNumber() == null || user.getPhoneNumber().isEmpty() ||
            user.getAddress() == null || user.getAddress().isEmpty()) {
            throw new IllegalStateException("Vui lòng cập nhật đầy đủ Số điện thoại và Địa chỉ trước khi yêu cầu xác thực.");
        }

        // Nếu là Seller, bắt buộc phải có Tên công ty/Trại giống
        if (user.getRole() == com.aquatrade.core.domain.enums.Role.SELLER && 
            (user.getCompanyName() == null || user.getCompanyName().isEmpty())) {
            throw new IllegalStateException("Vui lòng cập nhật Tên công ty/Trại giống trước khi yêu cầu xác thực.");
        }

        user.setVerificationStatus(com.aquatrade.core.domain.enums.VerificationStatus.PENDING);
        userRepository.save(user);
        log.info("Người dùng {} đã gửi yêu cầu xác thực tài khoản.", user.getEmail());
    }

    @Override
    public UserDto updateProfile(UserDto userDto) {
        UUID userId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng"));

        if (userDto.getFullName() != null) user.setFullName(userDto.getFullName());
        if (userDto.getPhoneNumber() != null) user.setPhoneNumber(userDto.getPhoneNumber());
        if (userDto.getAddress() != null) user.setAddress(userDto.getAddress());
        if (userDto.getCompanyName() != null) user.setCompanyName(userDto.getCompanyName());

        user = userRepository.save(user);
        return getCurrentUser();
    }
}
