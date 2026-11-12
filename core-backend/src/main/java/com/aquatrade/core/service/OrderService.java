package com.aquatrade.core.service;

import com.aquatrade.core.dto.OrderDto;
import java.util.List;
import java.util.UUID;

public interface OrderService {
    OrderDto.OrderResponse createOrder(OrderDto.CreateOrderRequest request);
    List<OrderDto.OrderResponse> checkoutCart(OrderDto.CartCheckoutRequest request);
    void lockEscrowAndPurchase(UUID orderId);
    OrderDto.OrderResponse getOrderById(UUID id);
    List<OrderDto.OrderResponse> getMyOrders();
    void confirmOrderQuantity(UUID id);
    void updateDigitalProof(UUID id, UUID proofId, com.aquatrade.core.dto.AIDetectionDto.DonePayload aiResult);
    void startAiAnalysis(UUID id, String videoUrl, String videoPublicId, String batchName, Integer batchExpectedQuantity);
    List<OrderDto.OrderResponse> getSellerOrders(UUID sellerId);
    void completeOrder(UUID id);
    void disputeOrder(UUID orderId, String reason);
    void respondToDispute(UUID orderId, String response);
    void refundOrder(UUID orderId);
    void adminReviewOrder(UUID orderId, Integer finalQuantity);
    void updateOrderStatus(UUID orderId, com.aquatrade.core.domain.enums.OrderStatus newStatus);
    void approvePayout(UUID orderId);
    void cancelOrder(UUID id);
}
