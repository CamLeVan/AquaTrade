package com.aquatrade.core.controller;

import com.aquatrade.core.dto.SellerDto;
import com.aquatrade.core.dto.response.ApiResponse;
import com.aquatrade.core.service.SellerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/seller")
@RequiredArgsConstructor
public class SellerController {

    private final SellerService sellerService;

    @GetMapping("/{sellerId}/stats")
    public ResponseEntity<ApiResponse<SellerDto.SellerStatsSummary>> getSellerStats(@PathVariable String sellerId) {
        return ResponseEntity.ok(ApiResponse.success(sellerService.getSellerStats(UUID.fromString(sellerId))));
    }
}
