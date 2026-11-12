package com.aquatrade.core.config;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.DependsOn;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
@Slf4j
@RequiredArgsConstructor
@DependsOn("entityManagerFactory")
public class DatabaseSchemaFixer {

    private final JdbcTemplate jdbcTemplate;

    @PostConstruct
    public void fixSchema() {
        fixListingStatusConstraint();
        fixUserVerificationStatusColumn();
        fixOrderStatusConstraint();
    }

    private void fixListingStatusConstraint() {
        try {
            log.info(">>> Đang cập nhật ràng buộc listings_status_check trong Database...");
            jdbcTemplate.execute("ALTER TABLE listings DROP CONSTRAINT IF EXISTS listings_status_check");
            jdbcTemplate.execute(
                    "ALTER TABLE listings ADD CONSTRAINT listings_status_check CHECK (status IN ('PENDING_REVIEW', 'AVAILABLE', 'SOLD', 'HIDDEN', 'REJECTED', 'DELETED'))");
            log.info(">>> Cập nhật Database thành công! Trạng thái DELETED hiện đã khả dụng.");
        } catch (Exception e) {
            log.warn(">>> Không thể cập nhật ràng buộc listings_status_check: {}", e.getMessage());
        }
    }

    private void fixOrderStatusConstraint() {
        try {
            log.info(">>> Đang XÓA HOÀN TOÀN ràng buộc orders_status_check trong Database để tránh lỗi enum...");
            jdbcTemplate.execute("ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check");
            log.info(">>> Đã xóa bỏ các check constraint cũ của bảng orders thành công!");
        } catch (Exception e) {
            log.warn(">>> Không thể xóa ràng buộc orders_status_check: {}", e.getMessage());
            
            // Fallback: Thử dùng block PL/pgSQL nếu lệnh cơ bản không hoạt động
            try {
                jdbcTemplate.execute("DO $$ " +
                        "DECLARE r record; " +
                        "BEGIN " +
                        "  FOR r IN (SELECT conname FROM pg_constraint con " +
                        "            JOIN pg_class rel ON rel.oid = con.conrelid " +
                        "            WHERE rel.relname = 'orders' AND con.contype = 'c') LOOP " +
                        "    EXECUTE 'ALTER TABLE orders DROP CONSTRAINT IF EXISTS ' || quote_ident(r.conname); " +
                        "  END LOOP; " +
                        "END $$;");
                log.info(">>> Đã xóa bằng PL/pgSQL thành công!");
            } catch (Exception ex) {
                log.warn(">>> Vẫn không thể xóa bằng PL/pgSQL: {}", ex.getMessage());
            }
        }
    }

    private void fixUserVerificationStatusColumn() {
        try {
            log.info(">>> Đang kiểm tra và thêm các cột cần thiết vào bảng users...");
            jdbcTemplate.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_status VARCHAR(255) DEFAULT 'UNVERIFIED'");
            jdbcTemplate.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT");
            log.info(">>> Cập nhật bảng users thành công!");
        } catch (Exception e) {
            log.warn(">>> Không thể cập nhật bảng users: {}", e.getMessage());
        }
    }
}
