package com.aquatrade.core.service.impl;

import com.aquatrade.core.domain.Order;
import com.aquatrade.core.domain.Review;
import com.aquatrade.core.domain.User;
import com.aquatrade.core.domain.enums.OrderStatus;
import com.aquatrade.core.dto.ReviewDto;
import com.aquatrade.core.repository.OrderRepository;
import com.aquatrade.core.repository.ReviewRepository;
import com.aquatrade.core.repository.UserRepository;
import com.aquatrade.core.service.ReviewService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReviewServiceImpl implements ReviewService {

    private final ReviewRepository reviewRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;

    @Override
    public void submitReview(String orderId, ReviewDto.CreateReviewRequest request) {
        Order order = orderRepository.findById(UUID.fromString(orderId))
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn hàng"));

        // Chỉ review khi đơn hàng COMPLETED
        if (order.getStatus() != OrderStatus.COMPLETED) {
            throw new IllegalArgumentException("Chỉ có thể đánh giá khi đơn hàng đã hoàn thành");
        }

        UUID reviewerId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User reviewer = userRepository.findById(reviewerId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy user"));

        // Target = seller của listing
        User target = order.getListing().getSeller();

        Review review = Review.builder()
                .order(order)
                .reviewer(reviewer)
                .target(target)
                .rating(request.getRating())
                .comment(request.getComment())
                .build();

        reviewRepository.save(review);
        log.info("Review mới: Order {} - Rating: {} - By: {}", orderId, request.getRating(), reviewer.getFullName());
    }
}
