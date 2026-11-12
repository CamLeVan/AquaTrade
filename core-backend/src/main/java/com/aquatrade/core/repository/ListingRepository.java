package com.aquatrade.core.repository;

import com.aquatrade.core.domain.Listing;
import com.aquatrade.core.domain.enums.ListingStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ListingRepository extends JpaRepository<Listing, UUID> {
    List<Listing> findByStatus(ListingStatus status);
    List<Listing> findByProvinceAndSpeciesAndStatus(String province, String species, ListingStatus status);
    List<Listing> findByProvinceAndStatus(String province, ListingStatus status);
    List<Listing> findBySpeciesAndStatus(String species, ListingStatus status);
    long countByStatus(ListingStatus status);
    long countBySeller_Id(UUID sellerId);
    List<Listing> findBySeller_Id(UUID sellerId);
    List<Listing> findBySeller_IdAndStatusNot(UUID sellerId, ListingStatus status);
    List<Listing> findByStatusNot(ListingStatus status);
}
