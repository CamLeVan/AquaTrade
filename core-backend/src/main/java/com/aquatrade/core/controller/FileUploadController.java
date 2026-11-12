package com.aquatrade.core.controller;

import com.aquatrade.core.dto.response.ApiResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1/files")
public class FileUploadController {

    private final String uploadDir = "uploads/";

    @PostMapping("/upload")
    public ResponseEntity<ApiResponse<String>> uploadFile(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Vui lòng chọn file để tải lên"));
        }

        try {
            // Tạo thư mục nếu chưa tồn tại
            Path path = Paths.get(uploadDir);
            if (!Files.exists(path)) {
                Files.createDirectories(path);
            }

            // Tạo tên file duy nhất tránh trùng lặp
            String extension = getFileExtension(file.getOriginalFilename());
            String fileName = UUID.randomUUID().toString() + extension;
            Path filePath = path.resolve(fileName);

            // Lưu file
            Files.copy(file.getInputStream(), filePath);
            
            // Trả về URL để Frontend truy cập (phần /uploads/ được Spring Boot phục vụ mặc định từ static)
            String fileUrl = "http://localhost:8080/uploads/" + fileName;
            
            log.info("Đã lưu file thành công: {}", fileUrl);
            return ResponseEntity.ok(ApiResponse.success(fileUrl));

        } catch (IOException e) {
            log.error("Lỗi khi lưu file", e);
            return ResponseEntity.internalServerError().body(ApiResponse.error("Lỗi server khi lưu file: " + e.getMessage()));
        }
    }

    private String getFileExtension(String fileName) {
        if (fileName == null) return "";
        int lastIndex = fileName.lastIndexOf(".");
        return lastIndex == -1 ? "" : fileName.substring(lastIndex);
    }
}
