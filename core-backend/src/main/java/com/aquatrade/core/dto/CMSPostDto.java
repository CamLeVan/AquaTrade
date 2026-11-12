package com.aquatrade.core.dto;

import lombok.Builder;
import lombok.Data;

/**
 * DTO quản lý nội dung bài viết (Blog/Tin tức) — Admin CMS.
 * 🔜 Cần thêm bảng `posts` trong DB.
 */
import com.aquatrade.core.domain.enums.PostCategory;
import com.aquatrade.core.domain.enums.PostStatus;

@Data
@Builder
public class CMSPostDto {
    private String id;
    private String title;
    private String content;          // Markdown hoặc HTML
    private PostCategory category;
    private PostStatus status;
    private String featuredImageUrl;
    private String author;
    private Integer viewCount;

}
