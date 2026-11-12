package com.aquatrade.core.controller;

import com.aquatrade.core.dto.ReviewDto;
import com.aquatrade.core.dto.response.ApiResponse;
import com.aquatrade.core.service.ReviewService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/orders/{orderId}/reviews")
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;

    @PostMapping
    @PreAuthorize("hasAnyRole('BUYER', 'SELLER')")
    public ResponseEntity<ApiResponse<String>> submitReview(
            @PathVariable String orderId,
            @Valid @RequestBody ReviewDto.CreateReviewRequest request) {
        reviewService.submitReview(orderId, request);
        return ResponseEntity.ok(ApiResponse.success("Đánh giá người bán thành công."));
    }
}
