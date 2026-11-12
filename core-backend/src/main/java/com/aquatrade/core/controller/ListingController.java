package com.aquatrade.core.controller;

import com.aquatrade.core.dto.ListingDto;
import com.aquatrade.core.dto.response.ApiResponse;
import com.aquatrade.core.service.ListingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import org.springframework.security.core.context.SecurityContextHolder;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/listings")
@RequiredArgsConstructor
public class ListingController {

    private final ListingService listingService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<ListingDto>>> getAllListings(
            @RequestParam(required = false) String province,
            @RequestParam(required = false) String species,
            @RequestParam(required = false) String sellerId) {
        return ResponseEntity.ok(ApiResponse.success(listingService.getAllListings(province, species, sellerId)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ListingDto>> getListingById(@PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.success(listingService.getListingById(UUID.fromString(id))));
    }

    @PostMapping
    @PreAuthorize("hasRole('SELLER')")
    public ResponseEntity<ApiResponse<ListingDto>> createListing(
            @Valid @RequestBody ListingDto.CreateListingRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                listingService.createListing(request), "Tạo tin đăng thành công"));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('SELLER')")
    public ResponseEntity<ApiResponse<ListingDto>> updateListing(
            @PathVariable String id,
            @Valid @RequestBody ListingDto.CreateListingRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                listingService.updateListing(UUID.fromString(id), request), "Cập nhật bài đăng thành công"));
    }

    @GetMapping("/my-listings")
    @PreAuthorize("hasRole('SELLER')")
    public ResponseEntity<ApiResponse<List<ListingDto>>> getMyListings() {
        UUID sellerId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return ResponseEntity.ok(ApiResponse.success(listingService.getSellerListings(sellerId)));
    }

    @PatchMapping("/{id}/price")
    @PreAuthorize("hasRole('SELLER')")
    public ResponseEntity<ApiResponse<ListingDto>> updatePrice(
            @PathVariable String id,
            @RequestBody java.util.Map<String, java.math.BigDecimal> body) {
        return ResponseEntity.ok(ApiResponse.success(
                listingService.updatePrice(UUID.fromString(id), body.get("price")), 
                "Cập nhật giá thành công"));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('SELLER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteListing(@PathVariable String id) {
        listingService.deleteListing(UUID.fromString(id));
        return ResponseEntity.ok(ApiResponse.success(null, "Xóa bài đăng thành công"));
    }
}
