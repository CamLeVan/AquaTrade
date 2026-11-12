package com.aquatrade.core.controller;

import com.aquatrade.core.dto.response.ApiResponse;
import com.aquatrade.core.service.DisputeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/disputes")
@RequiredArgsConstructor
public class AdminDisputeController {

    private final DisputeService disputeService;

    @PostMapping("/{disputeId}/refund")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<String>> refundOrder(@PathVariable String disputeId) {
        disputeService.refundOrder(disputeId);
        return ResponseEntity.ok(ApiResponse.success("Đã phân xử thắng cho Buyer. Tiền 100% Escrow Refunded."));
    }

    @PostMapping("/{disputeId}/force-complete")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<String>> forceCompleteOrder(@PathVariable String disputeId) {
        disputeService.forceComplete(disputeId);
        return ResponseEntity.ok(ApiResponse.success("Bác bỏ đơn kiện. Tiền Escrow giải ngân cho Seller (95%) và Platform (5%)."));
    }
}
