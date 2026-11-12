package com.aquatrade.core.controller;

import com.aquatrade.core.dto.CMSPostDto;
import com.aquatrade.core.dto.response.ApiResponse;
import com.aquatrade.core.service.impl.CMSPostServiceImpl;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/posts")
@RequiredArgsConstructor
public class CMSPostController {

    private final CMSPostServiceImpl cmsPostService;

    @GetMapping
    public ResponseEntity<ApiResponse<Object>> getAllPosts() {
        return ResponseEntity.ok(ApiResponse.success(cmsPostService.getAllPosts()));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<CMSPostDto>> createPost(@RequestBody CMSPostDto dto) {
        return ResponseEntity.ok(ApiResponse.success(cmsPostService.createPost(dto)));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<CMSPostDto>> updatePost(@PathVariable UUID id, @RequestBody CMSPostDto dto) {
        return ResponseEntity.ok(ApiResponse.success(cmsPostService.updatePost(id, dto)));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deletePost(@PathVariable UUID id) {
        cmsPostService.deletePost(id);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
