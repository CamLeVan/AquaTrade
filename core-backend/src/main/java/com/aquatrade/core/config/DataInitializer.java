package com.aquatrade.core.config;

import com.aquatrade.core.domain.User;
import com.aquatrade.core.domain.enums.Role;
import com.aquatrade.core.domain.enums.UserStatus;
import com.aquatrade.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;

import java.math.BigDecimal;

@Component
@ConditionalOnProperty(name = "app.demo.seed-enabled", havingValue = "true")
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final com.aquatrade.core.repository.ListingRepository listingRepository;
    private final com.aquatrade.core.repository.CMSPostRepository cmsPostRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.demo.admin-password:}")
    private String adminPassword;

    @Value("${app.demo.seller-password:}")
    private String sellerPassword;

    @Value("${app.demo.buyer-password:}")
    private String buyerPassword;

    @Override
    public void run(String... args) throws Exception {
        if (adminPassword.isBlank() || sellerPassword.isBlank() || buyerPassword.isBlank()) {
            throw new IllegalStateException(
                    "Demo seeding requires DEMO_ADMIN_PASSWORD, DEMO_SELLER_PASSWORD and DEMO_BUYER_PASSWORD");
        }
        // Kiểm tra nếu chưa có Admin thì tạo mặc định, nếu có rồi thì cập nhật mật khẩu, vai trò và ví
        var adminOpt = userRepository.findByEmail("admin@gmail.com");
        if (adminOpt.isPresent()) {
            User admin = adminOpt.get();
            admin.setPasswordHash(passwordEncoder.encode(adminPassword));
            admin.setRole(Role.ADMIN);
            admin.setWalletBalance(BigDecimal.valueOf(100000000));
            userRepository.save(admin);
        } else {
            User admin = User.builder()
                    .fullName("System Administrator")
                    .email("admin@gmail.com")
                    .passwordHash(passwordEncoder.encode(adminPassword))
                    .role(Role.ADMIN)
                    .status(UserStatus.ACTIVE)
                    .walletBalance(BigDecimal.valueOf(100000000))
                    .build();
            userRepository.save(admin);
            log.info(">>> Đã tạo tài khoản Admin mặc định: admin@gmail.com");
        }

        // Tạo thêm một Seller mẫu nếu cần, nếu có rồi thì cập nhật mật khẩu, vai trò
        User seller;
        var sellerOpt = userRepository.findByEmail("seller@gmail.com");
        if (sellerOpt.isPresent()) {
            seller = sellerOpt.get();
            seller.setPasswordHash(passwordEncoder.encode(sellerPassword));
            seller.setRole(Role.SELLER);
            userRepository.save(seller);
        } else {
            seller = User.builder()
                    .fullName("Aqua Farm Seller")
                    .email("seller@gmail.com")
                    .passwordHash(passwordEncoder.encode(sellerPassword))
                    .role(Role.SELLER)
                    .status(UserStatus.ACTIVE)
                    .walletBalance(BigDecimal.ZERO)
                    .companyName("Mekong Delta Seafood")
                    .build();
            userRepository.save(seller);
            log.info(">>> Đã tạo tài khoản Seller mẫu: seller@gmail.com");
        }

        // Tạo thêm một Buyer mẫu nếu cần, nếu có rồi thì cập nhật mật khẩu, vai trò và ví
        var buyerOpt = userRepository.findByEmail("buyer@gmail.com");
        if (buyerOpt.isPresent()) {
            User buyer = buyerOpt.get();
            buyer.setPasswordHash(passwordEncoder.encode(buyerPassword));
            buyer.setRole(Role.BUYER);
            buyer.setWalletBalance(BigDecimal.valueOf(50000000));
            userRepository.save(buyer);
        } else {
            User buyer = User.builder()
                    .fullName("Aqua Farm Buyer")
                    .email("buyer@gmail.com")
                    .passwordHash(passwordEncoder.encode(buyerPassword))
                    .role(Role.BUYER)
                    .status(UserStatus.ACTIVE)
                    .walletBalance(BigDecimal.valueOf(50000000))
                    .build();
            userRepository.save(buyer);
            log.info(">>> Đã tạo tài khoản Buyer mẫu: buyer@gmail.com");
        }

        // Tạo Listings mẫu nếu chưa có bài nào
        if (listingRepository.count() == 0) {
            com.aquatrade.core.domain.Listing listing1 = com.aquatrade.core.domain.Listing.builder()
                    .title("Tôm Thẻ Chân Trắng - Size 40 con/kg")
                    .category(com.aquatrade.core.domain.enums.ListingCategory.TOM)
                    .species("Tôm Thẻ")
                    .province("Sóc Trăng")
                    .sizeMin(BigDecimal.valueOf(3.5))
                    .sizeMax(BigDecimal.valueOf(4.2))
                    .pricePerFish(BigDecimal.valueOf(1500))
                    .estimatedQuantity(50000)
                    .availableQuantity(50000)
                    .status(com.aquatrade.core.domain.enums.ListingStatus.PENDING_REVIEW)
                    .seller(seller)
                    .thumbnailUrl("https://images.unsplash.com/photo-1553659971-f01207815844?auto=format&fit=crop&q=80&w=200")
                    .build();

            com.aquatrade.core.domain.Listing listing2 = com.aquatrade.core.domain.Listing.builder()
                    .title("Cá Tra Giống Miền Tây - Khỏe Mạnh")
                    .category(com.aquatrade.core.domain.enums.ListingCategory.CA)
                    .species("Cá Tra")
                    .province("An Giang")
                    .sizeMin(BigDecimal.valueOf(10.0))
                    .sizeMax(BigDecimal.valueOf(12.5))
                    .pricePerFish(BigDecimal.valueOf(800))
                    .estimatedQuantity(100000)
                    .availableQuantity(100000)
                    .status(com.aquatrade.core.domain.enums.ListingStatus.PENDING_REVIEW)
                    .seller(seller)
                    .thumbnailUrl("https://images.unsplash.com/photo-1524704659690-3f7a3fe41baa?auto=format&fit=crop&q=80&w=200")
                    .build();

            listingRepository.save(listing1);
            listingRepository.save(listing2);
            log.info(">>> Đã tạo 2 bài đăng mẫu đang chờ duyệt.");
        }

        // Tạo CMS Posts mẫu
        if (cmsPostRepository.count() == 0) {
            // Lấy user admin đã tạo ở trên để làm tác giả
            com.aquatrade.core.domain.User adminUser = userRepository.findByEmail("admin@aquatrade.com")
                    .orElse(null);

            if (adminUser != null) {
                com.aquatrade.core.domain.CMSPost post1 = com.aquatrade.core.domain.CMSPost.builder()
                        .title("Tiềm năng xuất khẩu thủy sản 2024")
                        .content("Nội dung phân tích về thị trường thủy sản Việt Nam trong năm 2024...")
                        .category(com.aquatrade.core.domain.enums.PostCategory.MARKETING)
                        .status(com.aquatrade.core.domain.enums.PostStatus.PUBLISHED)
                        .author(adminUser) // Dùng đối tượng User thực tế
                        .viewCount(1200)
                        .featuredImageUrl("https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&q=80&w=400")
                        .build();

                com.aquatrade.core.domain.CMSPost post2 = com.aquatrade.core.domain.CMSPost.builder()
                        .title("Công nghệ lọc nước tuần hoàn RAS")
                        .content("Hướng dẫn chi tiết về hệ thống RAS trong nuôi tôm công nghiệp...")
                        .category(com.aquatrade.core.domain.enums.PostCategory.TECH)
                        .status(com.aquatrade.core.domain.enums.PostStatus.DRAFT)
                        .author(adminUser) // Dùng đối tượng User thực tế
                        .viewCount(0)
                        .featuredImageUrl("https://images.unsplash.com/photo-1534321231932-e739d42830a9?auto=format&fit=crop&q=80&w=400")
                        .build();

                cmsPostRepository.save(post1);
                cmsPostRepository.save(post2);
                log.info(">>> Đã tạo 2 bài viết CMS mẫu.");
            }
        }
    }
}
