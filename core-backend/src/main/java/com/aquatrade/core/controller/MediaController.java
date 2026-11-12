package com.aquatrade.core.controller;

import com.aquatrade.core.dto.response.ApiResponse;
import com.aquatrade.core.dto.CloudinarySignatureResponse;
import com.aquatrade.core.service.CloudinaryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/media")
@RequiredArgsConstructor
public class MediaController {

    private final CloudinaryService cloudinaryService;

    /**
     * API cấp "Giấy thông hành" cho Frontend để upload video thẳng lên Cloudinary.
     * Bảo vệ API_SECRET không bị lộ ở phía Client.
     */
    @GetMapping("/upload-signature")
    public ResponseEntity<ApiResponse<CloudinarySignatureResponse>> getUploadSignature() {
        return ResponseEntity.ok(ApiResponse.success(cloudinaryService.generateSignature()));
    }

    /**
     * API lấy danh sách các video đã được upload sẵn trên Cloudinary (dành cho tính năng Check AI).
     */
    @GetMapping("/videos")
    public ResponseEntity<ApiResponse<java.util.List<String>>> getPreSavedVideos() {
        return ResponseEntity.ok(ApiResponse.success(cloudinaryService.getPreSavedVideos()));
    }
}
