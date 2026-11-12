package com.aquatrade.core.service.impl;

import com.aquatrade.core.domain.CMSPost;
import com.aquatrade.core.domain.User;
import com.aquatrade.core.dto.CMSPostDto;
import com.aquatrade.core.repository.CMSPostRepository;
import com.aquatrade.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CMSPostServiceImpl {

    private final CMSPostRepository cmsPostRepository;
    private final UserRepository userRepository;

    public List<CMSPostDto> getAllPosts() {
        return cmsPostRepository.findAll().stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public CMSPostDto createPost(CMSPostDto dto) {
        UUID adminId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User admin = userRepository.findById(adminId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy user admin"));

        CMSPost post = CMSPost.builder()
                .title(dto.getTitle())
                .content(dto.getContent())
                .category(dto.getCategory())
                .status(dto.getStatus())
                .featuredImageUrl(dto.getFeaturedImageUrl())
                .author(admin)
                .build();

        post = cmsPostRepository.save(post);
        return mapToDto(post);
    }

    @Transactional
    public CMSPostDto updatePost(UUID id, CMSPostDto dto) {
        CMSPost post = cmsPostRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy bài viết"));
        
        post.setTitle(dto.getTitle());
        post.setContent(dto.getContent());
        post.setCategory(dto.getCategory());
        post.setStatus(dto.getStatus());
        if (dto.getFeaturedImageUrl() != null) {
            post.setFeaturedImageUrl(dto.getFeaturedImageUrl());
        }
        
        return mapToDto(cmsPostRepository.save(post));
    }

    @Transactional
    public void deletePost(UUID id) {
        cmsPostRepository.deleteById(id);
    }

    private CMSPostDto mapToDto(CMSPost entity) {
        return CMSPostDto.builder()
                .id(entity.getId().toString())
                .title(entity.getTitle())
                .content(entity.getContent())
                .category(entity.getCategory())
                .status(entity.getStatus())
                .featuredImageUrl(entity.getFeaturedImageUrl())
                .author(entity.getAuthor().getFullName())
                .viewCount(entity.getViewCount())
                .build();
    }
}
