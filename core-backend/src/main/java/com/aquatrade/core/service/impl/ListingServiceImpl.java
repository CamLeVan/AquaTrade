package com.aquatrade.core.service.impl;

import com.aquatrade.core.domain.Listing;
import com.aquatrade.core.domain.User;
import com.aquatrade.core.domain.enums.ListingStatus;
import com.aquatrade.core.dto.ListingDto;
import com.aquatrade.core.repository.ListingRepository;
import com.aquatrade.core.repository.UserRepository;
import com.aquatrade.core.repository.OrderRepository;
import com.aquatrade.core.service.ListingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class ListingServiceImpl implements ListingService {

    private final ListingRepository listingRepository;
    private final UserRepository userRepository;
    private final OrderRepository orderRepository;

    @Override
    public List<ListingDto> getAllListings(String province, String species, String sellerId) {
        ListingStatus activeStatus = ListingStatus.AVAILABLE;
        List<Listing> listings = listingRepository.findByStatus(activeStatus);

        return listings.stream()
                .filter(l -> province == null || province.trim().isEmpty() || l.getProvince().equalsIgnoreCase(province.trim()))
                .filter(l -> species == null || species.trim().isEmpty() || l.getSpecies().equalsIgnoreCase(species.trim()))
                .filter(l -> sellerId == null || sellerId.trim().isEmpty() || l.getSeller().getId().toString().equals(sellerId.trim()))
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Override
    public ListingDto getListingById(UUID id) {
        Listing listing = listingRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy tin đăng với ID: " + id));
        return mapToDto(listing);
    }

    @Override
    public ListingDto createListing(ListingDto.CreateListingRequest request) {
        // Lấy Seller từ JWT SecurityContext (DỮ LIỆU THẬT)
        UUID sellerId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User seller = userRepository.findById(sellerId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy user seller"));

        Listing listing = Listing.builder()
                .title(request.getTitle())
                .category(request.getCategory())
                .species(request.getSpecies())
                .province(request.getProvince())
                .sizeMin(request.getSizeMin())
                .sizeMax(request.getSizeMax())
                .pricePerFish(request.getPricePerFish())
                .estimatedQuantity(request.getEstimatedQuantity())
                .availableQuantity(request.getEstimatedQuantity())
                .thumbnailUrl(request.getThumbnailUrl())
                .description(request.getDescription())
                // Quy trình chuẩn: Tin đăng mới ở trạng thái PENDING_REVIEW — chờ Admin duyệt mới hiển thị lên Chợ.
                .status(ListingStatus.PENDING_REVIEW)
                .seller(seller)
                .build();

        if (request.getImageUrls() != null) {
            for (String url : request.getImageUrls()) {
                listing.addImage(com.aquatrade.core.domain.ListingImage.builder()
                        .imageUrl(url)
                        .isThumbnail(url.equals(request.getThumbnailUrl()))
                        .build());
            }
        }

        listing = listingRepository.saveAndFlush(listing);
        log.info("Listing mới: {} - Seller: {}", listing.getTitle(), seller.getFullName());

        return mapToDto(listing);
    }

    @Override
    public List<ListingDto> getSellerListings(UUID sellerId) {
        log.info(">>> Đang tìm danh sách bài đăng cho Seller ID: {}", sellerId);
        List<Listing> results = listingRepository.findBySeller_IdAndStatusNot(sellerId, ListingStatus.DELETED);
        log.info(">>> Kết quả tìm kiếm: {} bài đăng (không tính DELETED) cho Seller ID: {}", results.size(), sellerId);
        
        return results.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Override
    public ListingDto updatePrice(UUID listingId, java.math.BigDecimal newPrice) {
        Listing listing = listingRepository.findById(listingId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sản phẩm"));
        
        listing.setPricePerFish(newPrice);
        return mapToDto(listingRepository.save(listing));
    }

    @Override
    public ListingDto updateListing(UUID id, ListingDto.CreateListingRequest request) {
        Listing listing = listingRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy tin đăng với ID: " + id));

        // Chỉ cho phép chủ sở hữu (Seller) sửa tin đăng của chính mình
        UUID currentUserId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (!listing.getSeller().getId().equals(currentUserId)) {
            throw new IllegalArgumentException("Bạn không có quyền chỉnh sửa tin đăng này.");
        }

        listing.setTitle(request.getTitle());
        listing.setCategory(request.getCategory());
        listing.setSpecies(request.getSpecies());
        listing.setProvince(request.getProvince());
        listing.setSizeMin(request.getSizeMin());
        listing.setSizeMax(request.getSizeMax());
        listing.setPricePerFish(request.getPricePerFish());
        listing.setEstimatedQuantity(request.getEstimatedQuantity());
        listing.setAvailableQuantity(request.getEstimatedQuantity()); // Cập nhật lại số lượng có sẵn
        listing.setThumbnailUrl(request.getThumbnailUrl());
        listing.setDescription(request.getDescription());

        // Cập nhật bộ sưu tập ảnh (ListingImages)
        listing.getImages().clear();
        if (request.getImageUrls() != null) {
            for (String url : request.getImageUrls()) {
                listing.addImage(com.aquatrade.core.domain.ListingImage.builder()
                        .imageUrl(url)
                        .isThumbnail(url.equals(request.getThumbnailUrl()))
                        .build());
            }
        }

        listing = listingRepository.save(listing);
        log.info("Cập nhật thành công tin đăng ID: {}", id);
        return mapToDto(listing);
    }

    private ListingDto mapToDto(Listing entity) {
        List<String> urls = entity.getImages() != null 
                ? entity.getImages().stream().map(com.aquatrade.core.domain.ListingImage::getImageUrl).collect(Collectors.toList())
                : java.util.Collections.emptyList();

        long purchaseCount = orderRepository.countOrdersByListingId(entity.getId());
        long soldQuantity = orderRepository.sumQuantityByListingId(entity.getId());

        return ListingDto.builder()
                .id(entity.getId().toString())
                .title(entity.getTitle())
                .category(entity.getCategory())
                .species(entity.getSpecies())
                .province(entity.getProvince())
                .sizeMin(entity.getSizeMin())
                .sizeMax(entity.getSizeMax())
                .pricePerFish(entity.getPricePerFish())
                .estimatedQuantity(entity.getEstimatedQuantity())
                .availableQuantity(entity.getAvailableQuantity())
                .thumbnailUrl(entity.getThumbnailUrl())
                .status(entity.getStatus())
                .sellerName(entity.getSeller().getFullName())
                .sellerId(entity.getSeller().getId().toString())
                .description(entity.getDescription())
                .imageUrls(urls)
                .createdAt(entity.getCreatedAt())
                .purchaseCount((int) purchaseCount)
                .soldQuantity((int) soldQuantity)
                .build();
    }

    @Override
    public void deleteListing(UUID id) {
        Listing listing = listingRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy tin đăng với ID: " + id));
        
        // Kiểm tra xem tin đăng này đã có đơn hàng nào chưa
        boolean hasOrders = orderRepository.existsByListingId(id);
        
        if (hasOrders) {
            // Nếu đã có đơn hàng, chỉ xóa mềm (Soft Delete) bằng cách đổi trạng thái
            listing.setStatus(ListingStatus.DELETED);
            listingRepository.save(listing);
            log.info("Đã chuyển trạng thái tin đăng ID: {} sang DELETED (do đã có đơn hàng liên kết)", id);
        } else {
            // Nếu chưa có đơn hàng, cho phép xóa cứng (Hard Delete)
            listingRepository.delete(listing);
            log.info("Đã xóa vĩnh viễn tin đăng ID: {}", id);
        }
    }
}
