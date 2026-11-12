package com.aquatrade.core.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * DTO cài đặt người dùng — Settings page.
 * 🔜 Cần thêm bảng `user_settings`, `notification_preferences` trong DB.
 */
@Data
@Builder
public class UserSettingsDto {
    private String username;
    private String phone;
    private Boolean twoFactorEnabled;
    private List<LoginRecord> loginHistory;
    private Map<String, Boolean> notificationPreferences; // VD: {"QUALITY_ALERT": true, "PRICE_CHART": false}
    private List<PaymentCard> paymentMethods;

    @Data
    @Builder
    public static class LoginRecord {
        private String device;
        private String location;
        private LocalDateTime lastActive;
    }

    @Data
    @Builder
    public static class PaymentCard {
        private String cardType;     // VISA, MASTERCARD...
        private String last4;        // "4242"
        private String expiryDate;   // "12/28"
        private Boolean isDefault;
    }
}
