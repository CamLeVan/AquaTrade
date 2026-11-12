package com.aquatrade.core.controller;

import com.aquatrade.core.dto.DisputeDto;
import com.aquatrade.core.dto.response.ApiResponse;
import com.aquatrade.core.service.DisputeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/orders/{orderId}/disputes")
@RequiredArgsConstructor
public class DisputeController {

    private final DisputeService disputeService;

    @PostMapping
    @PreAuthorize("hasAnyRole('BUYER', 'SELLER')")
    public ResponseEntity<ApiResponse<DisputeDto.DisputeResponse>> createDispute(
            @PathVariable String orderId,
            @Valid @RequestBody DisputeDto.CreateDisputeRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                disputeService.createDispute(orderId, request),
                "Đã gửi khiếu nại thành công. Admin sẽ xử lý trong 24h."));
    }
}
