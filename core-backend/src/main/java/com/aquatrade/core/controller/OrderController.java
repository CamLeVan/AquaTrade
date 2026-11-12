package com.aquatrade.core.controller;

import com.aquatrade.core.dto.OrderDto;
import com.aquatrade.core.dto.response.ApiResponse;
import com.aquatrade.core.service.OrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;
    
    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/fix-db")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<String> fixDb() {
        try {
            jdbcTemplate.execute("ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check");
            jdbcTemplate.execute("ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check1");
            return ResponseEntity.ok("Dropped successfully!");
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }
    
    private final com.aquatrade.core.repository.OrderRepository orderRepository;

    @GetMapping("/escrow-details")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<OrderDto.OrderResponse>>> getEscrowDetails() {
        return ResponseEntity.ok(ApiResponse.success(
                orderRepository.findAll().stream()
                        .filter(o -> o.getStatus() != com.aquatrade.core.domain.enums.OrderStatus.COMPLETED 
                                  && o.getStatus() != com.aquatrade.core.domain.enums.OrderStatus.CANCELLED)
                        .map(order -> OrderDto.OrderResponse.builder()
                                .id(order.getId().toString())
                                .listingTitle(order.getListing().getTitle())
                                .buyerName(order.getBuyer().getFullName())
                                .sellerName(order.getListing().getSeller().getFullName())
                                .finalQuantity(order.getFinalQuantity())
                                .totalPrice(order.getTotalPrice())
                                .status(order.getStatus())
                                .createdAt(order.getCreatedAt())
                                .build())
                        .toList()
        ));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('BUYER', 'SELLER')")
    public ResponseEntity<ApiResponse<OrderDto.OrderResponse>> createOrder(
            @Valid @RequestBody OrderDto.CreateOrderRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                orderService.createOrder(request), "Khởi tạo Order thành công"));
    }

    @PostMapping("/checkout-cart")
    @PreAuthorize("hasAnyRole('BUYER', 'SELLER')")
    public ResponseEntity<ApiResponse<List<OrderDto.OrderResponse>>> checkoutCart(
            @Valid @RequestBody OrderDto.CartCheckoutRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                orderService.checkoutCart(request), "Thanh toán giỏ hàng thành công"));
    }

    @PostMapping("/{id}/lock-escrow")
    @PreAuthorize("hasRole('BUYER')")
    public ResponseEntity<ApiResponse<String>> lockEscrowAndPurchase(@PathVariable String id) {
        orderService.lockEscrowAndPurchase(UUID.fromString(id));
        return ResponseEntity.ok(ApiResponse.success("Đã khóa ví Escrow và xác nhận mua đơn hàng thành công!"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<OrderDto.OrderResponse>> getOrder(@PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.success(orderService.getOrderById(UUID.fromString(id))));
    }

    @GetMapping("/my")
    public ResponseEntity<ApiResponse<List<OrderDto.OrderResponse>>> getMyOrders() {
        UUID currentUserId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        List<OrderDto.OrderResponse> orders = orderService.getMyOrders();
        System.out.println(">>> [DEBUG] Fetching orders for Buyer ID: " + currentUserId + " | Count: " + orders.size());
        return ResponseEntity.ok(ApiResponse.success(orders));
    }

    @GetMapping("/seller")
    @PreAuthorize("hasRole('SELLER')")
    public ResponseEntity<ApiResponse<List<OrderDto.OrderResponse>>> getSellerOrders() {
        UUID sellerId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        List<OrderDto.OrderResponse> orders = orderService.getSellerOrders(sellerId);
        System.out.println(">>> [DEBUG] Fetching orders for Seller ID: " + sellerId + " | Count: " + orders.size());
        return ResponseEntity.ok(ApiResponse.success(orders));
    }

    @PostMapping("/{id}/confirm")
    @PreAuthorize("hasRole('BUYER')")
    public ResponseEntity<ApiResponse<String>> confirmOrderQuantity(@PathVariable String id) {
        orderService.confirmOrderQuantity(UUID.fromString(id));
        return ResponseEntity.ok(ApiResponse.success("Đã ghi nhận đối soát tự động từ AI hai chiều."));
    }

    @PostMapping("/{id}/start-ai")
    @PreAuthorize("hasAnyRole('SELLER', 'BUYER')")
    public ResponseEntity<ApiResponse<String>> startAiAnalysis(
            @PathVariable String id,
            @Valid @RequestBody OrderDto.StartAiRequest request) {
        orderService.startAiAnalysis(UUID.fromString(id), request.getVideoUrl(), request.getVideoPublicId(),
                request.getBatchName(), request.getBatchExpectedQuantity());
        return ResponseEntity.ok(ApiResponse.success("Đã gửi yêu cầu kiểm định sang bộ phận AI."));
    }

    @PostMapping("/{id}/complete")
    @PreAuthorize("hasRole('BUYER')")
    public ResponseEntity<ApiResponse<String>> completeOrder(@PathVariable String id) {
        orderService.completeOrder(UUID.fromString(id));
        return ResponseEntity.ok(ApiResponse.success("Đã xác nhận nhận hàng. Đang chờ Admin duyệt chi."));
    }

    @PostMapping("/{id}/approve-payout")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<String>> approvePayout(@PathVariable String id) {
        orderService.approvePayout(UUID.fromString(id));
        return ResponseEntity.ok(ApiResponse.success("Đã duyệt giải ngân tiền cho người bán."));
    }

    @PostMapping("/{id}/review")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<String>> adminReviewOrder(
            @PathVariable String id,
            @RequestParam Integer finalQuantity) {
        orderService.adminReviewOrder(UUID.fromString(id), finalQuantity);
        return ResponseEntity.ok(ApiResponse.success("Phê duyệt số lượng đơn hàng thành công. Dòng tiền đã được điều chỉnh."));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('SELLER', 'ADMIN')")
    public ResponseEntity<ApiResponse<String>> updateOrderStatus(
            @PathVariable String id,
            @RequestParam com.aquatrade.core.domain.enums.OrderStatus status) {
        orderService.updateOrderStatus(UUID.fromString(id), status);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật trạng thái đơn hàng thành công."));
    }

    @PostMapping("/{id}/dispute")
    @PreAuthorize("hasRole('BUYER')")
    public ResponseEntity<ApiResponse<String>> disputeOrder(
            @PathVariable String id,
            @RequestParam String reason) {
        orderService.disputeOrder(UUID.fromString(id), reason);
        return ResponseEntity.ok(ApiResponse.success("Đã gửi khiếu nại đơn hàng. Vui lòng chờ phản hồi."));
    }

    @PostMapping("/{id}/respond-dispute")
    @PreAuthorize("hasRole('SELLER')")
    public ResponseEntity<ApiResponse<String>> respondToDispute(
            @PathVariable String id,
            @RequestParam String comment) {
        orderService.respondToDispute(UUID.fromString(id), comment);
        return ResponseEntity.ok(ApiResponse.success("Đã gửi phản hồi khiếu nại."));
    }

    @PostMapping("/{id}/refund")
    @PreAuthorize("hasAnyRole('SELLER', 'ADMIN')")
    public ResponseEntity<ApiResponse<String>> refundOrder(@PathVariable String id) {
        orderService.refundOrder(UUID.fromString(id));
        return ResponseEntity.ok(ApiResponse.success("Phê duyệt hoàn tiền thành công. Tiền (90%) đã được chuyển lại cho người mua."));
    }
}
