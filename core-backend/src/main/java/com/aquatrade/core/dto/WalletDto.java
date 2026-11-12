package com.aquatrade.core.dto;

import com.aquatrade.core.domain.enums.TransactionType;
import com.aquatrade.core.domain.enums.TransactionStatus;
import com.aquatrade.core.domain.enums.PaymentMethod;
import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class WalletDto {

    @Data
    @Builder
    public static class DepositRequest {
        private BigDecimal amount;
        private PaymentMethod paymentMethod;
    }
    private BigDecimal walletBalance;
    private BigDecimal escrowBalance;
    private BigDecimal totalIncome;
    private String userLevel;
    private List<TransactionDto> recentTransactions;

    @Data
    @Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class TransactionDto {
        private String id;
        private String orderId;
        private String userName;
        private String userEmail;
        private BigDecimal amount;
        private BigDecimal postBalance;
        private TransactionType type;
        private PaymentMethod paymentMethod;
        private TransactionStatus status;
        private String note;
        private LocalDateTime createdAt;
    }
}
