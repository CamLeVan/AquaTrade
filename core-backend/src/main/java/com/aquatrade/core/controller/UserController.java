package com.aquatrade.core.controller;

import com.aquatrade.core.dto.UserDto;
import com.aquatrade.core.dto.response.ApiResponse;
import com.aquatrade.core.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserDto>> getCurrentUser() {
        return ResponseEntity.ok(ApiResponse.success(userService.getCurrentUser()));
    }

    @PostMapping("/request-verification")
    public ResponseEntity<ApiResponse<String>> requestVerification() {
        userService.requestVerification();
        return ResponseEntity.ok(ApiResponse.success("Yêu cầu xác thực đã được gửi đi thành công."));
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<UserDto>> updateProfile(@RequestBody UserDto userDto) {
        return ResponseEntity.ok(ApiResponse.success(userService.updateProfile(userDto)));
    }
}
