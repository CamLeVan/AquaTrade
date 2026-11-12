package com.aquatrade.core.controller;

import com.aquatrade.core.dto.AIDetectionDto;
import com.aquatrade.core.dto.response.ApiResponse;
import com.aquatrade.core.service.OrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/internal/orders")
@RequiredArgsConstructor
public class InternalOrderController {

    private final OrderService orderService;

    @PostMapping("/{orderId}/proofs/{proofId}/ai-result")
    public ResponseEntity<ApiResponse<String>> updateAiResult(
            @PathVariable UUID orderId,
            @PathVariable UUID proofId,
            @RequestBody AIDetectionDto.DonePayload aiResult) {
        
        orderService.updateDigitalProof(orderId, proofId, aiResult);
        return ResponseEntity.ok(ApiResponse.success("AI Result updated and broadcasted"));
    }
}
