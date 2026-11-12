package com.aquatrade.core.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CloudinarySignatureResponse {
    private String signature;
    private Long timestamp;
    private String apiKey;
    private String cloudName;
    private String uploadPreset;
}
