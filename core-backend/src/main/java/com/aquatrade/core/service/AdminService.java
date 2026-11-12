package com.aquatrade.core.service;

import com.aquatrade.core.dto.AdminDto;

public interface AdminService {
    void moderateListing(String listingId, AdminDto.ModerateListingRequest request);
    java.util.List<com.aquatrade.core.dto.ListingDto> getAllPendingListings();

    // [NEW] Quản lý Users
    java.util.List<AdminDto.UserSummary> getAllUsers();
    void toggleUserStatus(String userId, AdminDto.ToggleUserStatusRequest request);
    void verifyUser(String userId, boolean approved);
    AdminDto.UserSummary createUser(com.aquatrade.core.dto.AuthDto.RegisterRequest request);

    // [NEW] Giám sát Orders
    java.util.List<AdminDto.OrderSummary> getAllOrders();

    // [NEW] Giám sát Disputes
    java.util.List<AdminDto.DisputeSummary> getAllOpenDisputes();

    // [NEW] Xem Treasury
    AdminDto.TreasurySummary getTreasury();

    AdminDto.SystemStatsSummary getSystemStats();
    java.util.List<com.aquatrade.core.dto.ListingDto> getAllListings();
}
