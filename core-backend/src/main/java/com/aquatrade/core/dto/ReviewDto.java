package com.aquatrade.core.dto;

import lombok.Data;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public class ReviewDto {
    @Data
    public static class CreateReviewRequest {
        @NotNull
        @Min(1) @Max(5)
        private Integer rating;
        
        private String comment;
    }
}
