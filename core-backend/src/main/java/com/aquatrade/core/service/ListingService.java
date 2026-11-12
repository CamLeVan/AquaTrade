package com.aquatrade.core.service;

import com.aquatrade.core.dto.ListingDto;
import java.util.List;
import java.util.UUID;

public interface ListingService {
    List<ListingDto> getAllListings(String province, String species, String sellerId);
    ListingDto getListingById(UUID id);
    ListingDto createListing(ListingDto.CreateListingRequest request);
    List<ListingDto> getSellerListings(UUID sellerId);
    ListingDto updatePrice(UUID listingId, java.math.BigDecimal newPrice);
    ListingDto updateListing(UUID id, ListingDto.CreateListingRequest request);
    void deleteListing(UUID id);
}
