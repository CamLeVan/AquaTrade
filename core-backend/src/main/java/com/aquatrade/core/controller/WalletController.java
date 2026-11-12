package com.aquatrade.core.controller;

import com.aquatrade.core.dto.WalletDto;
import com.aquatrade.core.dto.response.ApiResponse;
import com.aquatrade.core.service.WalletService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/users/me/wallet")
@RequiredArgsConstructor
public class WalletController {

    private final WalletService walletService;

    @GetMapping
    public ResponseEntity<ApiResponse<WalletDto>> getMyWallet() {
        return ResponseEntity.ok(ApiResponse.success(walletService.getMyWallet()));
    }

    @PostMapping("/deposit")
    public ResponseEntity<ApiResponse<String>> deposit(@RequestBody WalletDto.DepositRequest request) {
        walletService.deposit(request);
        return ResponseEntity.ok(ApiResponse.success("Yêu cầu nạp tiền đã được gửi, vui lòng chờ Admin duyệt"));
    }

    @GetMapping("/admin/pending")
    @org.springframework.security.access.prepost.PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<java.util.List<com.aquatrade.core.dto.WalletDto.TransactionDto>>> getPendingDeposits() {
        return ResponseEntity.ok(ApiResponse.success(walletService.getAllPendingDeposits()));
    }

    @PostMapping("/admin/approve/{id}")
    @org.springframework.security.access.prepost.PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<String>> approveDeposit(@PathVariable String id) {
        walletService.approveDeposit(id);
        return ResponseEntity.ok(ApiResponse.success("Đã duyệt nạp tiền thành công"));
    }

    @PostMapping("/admin/reject/{id}")
    @org.springframework.security.access.prepost.PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<String>> rejectDeposit(@PathVariable String id) {
        walletService.rejectDeposit(id);
        return ResponseEntity.ok(ApiResponse.success("Đã từ chối nạp tiền"));
    }
}
