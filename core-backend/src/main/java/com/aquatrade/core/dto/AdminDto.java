package com.aquatrade.core.dto;

import com.aquatrade.core.domain.enums.UserStatus;
import com.aquatrade.core.domain.enums.ListingStatus;
import com.aquatrade.core.domain.enums.DisputeStatus;
import com.aquatrade.core.domain.enums.OrderStatus;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;
import java.util.List;

public class AdminDto {

    public static class ModerateListingRequest {
        private ListingStatus moderationStatus;
        private String moderationNote;

        public ModerateListingRequest() {}
        public ModerateListingRequest(ListingStatus moderationStatus, String moderationNote) {
            this.moderationStatus = moderationStatus;
            this.moderationNote = moderationNote;
        }
        public ListingStatus getModerationStatus() { return moderationStatus; }
        public void setModerationStatus(ListingStatus status) { this.moderationStatus = status; }
        public String getModerationNote() { return moderationNote; }
        public void setModerationNote(String note) { this.moderationNote = note; }
    }

    public static class ToggleUserStatusRequest {
        private UserStatus newStatus;

        public ToggleUserStatusRequest() {}
        public ToggleUserStatusRequest(UserStatus newStatus) {
            this.newStatus = newStatus;
        }
        public UserStatus getNewStatus() { return newStatus; }
        public void setNewStatus(UserStatus status) { this.newStatus = status; }
    }

    public static class UserSummary {
        private UUID id;
        private String fullName;
        private String email;
        private String role;
        private String avatarUrl;
        private UserStatus status;
        private com.aquatrade.core.domain.enums.VerificationStatus verificationStatus;
        private String phoneNumber;
        private String address;
        private String companyName;
        private LocalDateTime createdAt;

        public UserSummary() {}
        public UserSummary(UUID id, String fullName, String email, String role, String avatarUrl, UserStatus status, com.aquatrade.core.domain.enums.VerificationStatus verificationStatus, String phoneNumber, String address, String companyName, LocalDateTime createdAt) {
            this.id = id;
            this.fullName = fullName;
            this.email = email;
            this.role = role;
            this.avatarUrl = avatarUrl;
            this.status = status;
            this.verificationStatus = verificationStatus;
            this.phoneNumber = phoneNumber;
            this.address = address;
            this.companyName = companyName;
            this.createdAt = createdAt;
        }
        public UUID getId() { return id; }
        public void setId(UUID id) { this.id = id; }
        public String getFullName() { return fullName; }
        public void setFullName(String fullName) { this.fullName = fullName; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getRole() { return role; }
        public void setRole(String role) { this.role = role; }
        public String getAvatarUrl() { return avatarUrl; }
        public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }
        public UserStatus getStatus() { return status; }
        public void setStatus(UserStatus status) { this.status = status; }
        public com.aquatrade.core.domain.enums.VerificationStatus getVerificationStatus() { return verificationStatus; }
        public void setVerificationStatus(com.aquatrade.core.domain.enums.VerificationStatus status) { this.verificationStatus = status; }
        public String getPhoneNumber() { return phoneNumber; }
        public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
        public String getAddress() { return address; }
        public void setAddress(String address) { this.address = address; }
        public String getCompanyName() { return companyName; }
        public void setCompanyName(String companyName) { this.companyName = companyName; }
        public LocalDateTime getCreatedAt() { return createdAt; }
        public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    }

    public static class OrderSummary {
        private UUID id;
        private String listingTitle;
        private String buyerName;
        private String sellerName;
        private ListingStatus listingStatus;
        private OrderStatus orderStatus;
        private BigDecimal totalPrice;
        private Integer finalQuantity;
        private BigDecimal unitPriceAtPurchase;
        private LocalDateTime createdAt;

        public OrderSummary() {}
        public OrderSummary(UUID id, String listingTitle, String buyerName, String sellerName, ListingStatus listingStatus, OrderStatus orderStatus, BigDecimal totalPrice, Integer finalQuantity, BigDecimal unitPriceAtPurchase, LocalDateTime createdAt) {
            this.id = id;
            this.listingTitle = listingTitle;
            this.buyerName = buyerName;
            this.sellerName = sellerName;
            this.listingStatus = listingStatus;
            this.orderStatus = orderStatus;
            this.totalPrice = totalPrice;
            this.finalQuantity = finalQuantity;
            this.unitPriceAtPurchase = unitPriceAtPurchase;
            this.createdAt = createdAt;
        }
        public UUID getId() { return id; }
        public void setId(UUID id) { this.id = id; }
        public String getListingTitle() { return listingTitle; }
        public void setListingTitle(String listingTitle) { this.listingTitle = listingTitle; }
        public String getBuyerName() { return buyerName; }
        public void setBuyerName(String buyerName) { this.buyerName = buyerName; }
        public String getSellerName() { return sellerName; }
        public void setSellerName(String sellerName) { this.sellerName = sellerName; }
        public ListingStatus getListingStatus() { return listingStatus; }
        public void setListingStatus(ListingStatus listingStatus) { this.listingStatus = listingStatus; }
        public OrderStatus getOrderStatus() { return orderStatus; }
        public void setOrderStatus(OrderStatus orderStatus) { this.orderStatus = orderStatus; }
        public BigDecimal getTotalPrice() { return totalPrice; }
        public void setTotalPrice(BigDecimal totalPrice) { this.totalPrice = totalPrice; }
        public Integer getFinalQuantity() { return finalQuantity; }
        public void setFinalQuantity(Integer finalQuantity) { this.finalQuantity = finalQuantity; }
        public BigDecimal getUnitPriceAtPurchase() { return unitPriceAtPurchase; }
        public void setUnitPriceAtPurchase(BigDecimal unitPriceAtPurchase) { this.unitPriceAtPurchase = unitPriceAtPurchase; }
        public LocalDateTime getCreatedAt() { return createdAt; }
        public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    }

    public static class DisputeSummary {
        private UUID id;
        private String orderId;
        private String complainerName;
        private DisputeStatus status;
        private LocalDateTime createdAt;

        public DisputeSummary() {}
        public DisputeSummary(UUID id, String orderId, String complainerName, DisputeStatus status, LocalDateTime createdAt) {
            this.id = id;
            this.orderId = orderId;
            this.complainerName = complainerName;
            this.status = status;
            this.createdAt = createdAt;
        }
        public UUID getId() { return id; }
        public void setId(UUID id) { this.id = id; }
        public String getOrderId() { return orderId; }
        public void setOrderId(String orderId) { this.orderId = orderId; }
        public String getComplainerName() { return complainerName; }
        public void setComplainerName(String complainerName) { this.complainerName = complainerName; }
        public DisputeStatus getStatus() { return status; }
        public void setStatus(DisputeStatus status) { this.status = status; }
        public LocalDateTime getCreatedAt() { return createdAt; }
        public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    }

    public static class SystemStatsSummary {
        private BigDecimal totalRevenue;
        private long totalUsers;
        private long openDisputes;
        private double aiAccuracy;
        private long activeListings;
        private long totalListings;
        private long pendingListings;
        private long pendingVerifications;
        private List<DailyStat> dailyStats;

        public SystemStatsSummary() {}
        public SystemStatsSummary(BigDecimal totalRevenue, long totalUsers, long openDisputes, double aiAccuracy, long activeListings, long totalListings, long pendingListings, long pendingVerifications, List<DailyStat> dailyStats) {
            this.totalRevenue = totalRevenue;
            this.totalUsers = totalUsers;
            this.openDisputes = openDisputes;
            this.aiAccuracy = aiAccuracy;
            this.activeListings = activeListings;
            this.totalListings = totalListings;
            this.pendingListings = pendingListings;
            this.pendingVerifications = pendingVerifications;
            this.dailyStats = dailyStats;
        }
        public BigDecimal getTotalRevenue() { return totalRevenue; }
        public void setTotalRevenue(BigDecimal totalRevenue) { this.totalRevenue = totalRevenue; }
        public long getTotalUsers() { return totalUsers; }
        public void setTotalUsers(long totalUsers) { this.totalUsers = totalUsers; }
        public long getOpenDisputes() { return openDisputes; }
        public void setOpenDisputes(long openDisputes) { this.openDisputes = openDisputes; }
        public double getAiAccuracy() { return aiAccuracy; }
        public void setAiAccuracy(double aiAccuracy) { this.aiAccuracy = aiAccuracy; }
        public long getActiveListings() { return activeListings; }
        public void setActiveListings(long activeListings) { this.activeListings = activeListings; }
        public long getTotalListings() { return totalListings; }
        public void setTotalListings(long totalListings) { this.totalListings = totalListings; }
        public long getPendingListings() { return pendingListings; }
        public void setPendingListings(long pendingListings) { this.pendingListings = pendingListings; }
        public long getPendingVerifications() { return pendingVerifications; }
        public void setPendingVerifications(long pendingVerifications) { this.pendingVerifications = pendingVerifications; }
        public List<DailyStat> getDailyStats() { return dailyStats; }
        public void setDailyStats(List<DailyStat> dailyStats) { this.dailyStats = dailyStats; }
    }

    public static class DailyStat {
        private String date;
        private long value;

        public DailyStat() {}
        public DailyStat(String date, long value) {
            this.date = date;
            this.value = value;
        }
        public String getDate() { return date; }
        public void setDate(String date) { this.date = date; }
        public long getValue() { return value; }
        public void setValue(long value) { this.value = value; }
    }

    public static class TreasurySummary {
        private BigDecimal totalRevenue;

        public TreasurySummary() {}
        public TreasurySummary(BigDecimal totalRevenue) {
            this.totalRevenue = totalRevenue;
        }
        public BigDecimal getTotalRevenue() { return totalRevenue; }
        public void setTotalRevenue(BigDecimal totalRevenue) { this.totalRevenue = totalRevenue; }
    }
}
