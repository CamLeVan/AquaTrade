package com.aquatrade.core.service;

import com.aquatrade.core.dto.ReviewDto;

public interface ReviewService {
    void submitReview(String orderId, ReviewDto.CreateReviewRequest request);
}
