package com.aquatrade.core.config;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

@Slf4j
@Configuration
public class DatabaseFixer {

    @PersistenceContext
    private EntityManager entityManager;

    @Bean
    public CommandLineRunner fixDb(PlatformTransactionManager transactionManager) {
        return args -> {
            TransactionTemplate transactionTemplate = new TransactionTemplate(transactionManager);
            transactionTemplate.execute(status -> {
                try {
                    log.info(">>> [DB_FIX] Khởi tạo quá trình sửa ràng buộc OrderStatus...");
                    
                    // Xóa ràng buộc cũ
                    entityManager.createNativeQuery("ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check").executeUpdate();
                    
                    // Thêm ràng buộc mới hỗ trợ các trạng thái PREPARING, SHIPPING, DELIVERED, AI_VERIFIED
                    String sql = "ALTER TABLE orders ADD CONSTRAINT orders_status_check CHECK (status IN (" +
                                 "'PENDING', 'IN_VIDEO_CALL', 'COUNTING_AI', 'ESCROW_LOCKED', " +
                                 "'PENDING_ADMIN_REVIEW', 'PREPARING', 'SHIPPING', 'DELIVERED', " +
                                 "'AI_VERIFIED', 'READY_TO_PAYOUT', 'COMPLETED', 'DISPUTED', 'CANCELLED'))";
                    
                    entityManager.createNativeQuery(sql).executeUpdate();
                    
                    log.info(">>> [DB_FIX] THÀNH CÔNG: Đã cập nhật ràng buộc orders_status_check.");
                } catch (Exception e) {
                    log.error(">>> [DB_FIX] LỖI: Không thể cập nhật ràng buộc: {}", e.getMessage());
                }
                return null;
            });
        };
    }
}
