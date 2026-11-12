package com.aquatrade.core.service;

import com.aquatrade.core.dto.WalletDto;

public interface WalletService {
    WalletDto getMyWallet();
    void deposit(WalletDto.DepositRequest request);
    java.util.List<WalletDto.TransactionDto> getAllPendingDeposits();
    void approveDeposit(String transactionId);
    void rejectDeposit(String transactionId);
}
