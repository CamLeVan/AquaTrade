package com.aquatrade.core.domain;

import com.aquatrade.core.domain.base.BaseObject;
import com.aquatrade.core.domain.enums.PostCategory;
import com.aquatrade.core.domain.enums.PostStatus;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "cms_posts")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CMSPost extends BaseObject {

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;

    @Enumerated(EnumType.STRING)
    private PostCategory category;

    @Enumerated(EnumType.STRING)
    private PostStatus status;

    private String featuredImageUrl;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id", nullable = false)
    private User author;

    @Builder.Default
    private Integer viewCount = 0;

    @Version
    private Integer version;
}
