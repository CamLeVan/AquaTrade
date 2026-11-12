package com.aquatrade.core.service;

import com.aquatrade.core.dto.UserDto;

public interface UserService {
    // TODO: sau khi có JWT, thay userId = lấy từ SecurityContextHolder
    UserDto getCurrentUser();
    void requestVerification();
    UserDto updateProfile(UserDto userDto);
}
