package com.aquatrade.core.service;

import com.aquatrade.core.dto.CloudinarySignatureResponse;
import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.util.Collections;

@Service
public class CloudinaryService {

    @Value("${cloudinary.cloud-name}")
    private String cloudName;

    @Value("${cloudinary.api-key}")
    private String apiKey;

    @Value("${cloudinary.api-secret}")
    private String apiSecret;

    @Value("${cloudinary.video-preset}")
    private String videoPreset;

    /**
     * Tạo chữ ký bảo mật để Frontend có thể upload trực tiếp lên Cloudinary.
     * @return DTO chứa signature và timestamp
     */
    public CloudinarySignatureResponse generateSignature() {
        Cloudinary cloudinary = new Cloudinary(ObjectUtils.asMap(
                "cloud_name", cloudName,
                "api_key", apiKey,
                "api_secret", apiSecret));

        long timestamp = System.currentTimeMillis() / 1000L;
        
        Map<String, Object> params = new HashMap<>();
        params.put("timestamp", timestamp);
        params.put("upload_preset", videoPreset);
        params.put("folder", "aquatrade/videos");

        String signature = cloudinary.apiSignRequest(params, apiSecret);

        return CloudinarySignatureResponse.builder()
                .signature(signature)
                .timestamp(timestamp)
                .apiKey(apiKey)
                .cloudName(cloudName)
                .uploadPreset(videoPreset)
                .build();
    }

    /**
     * Lấy danh sách video đã được upload sẵn trên Cloudinary.
     * @return Danh sách URL của các video.
     */
    public List<String> getPreSavedVideos() {
        try {
            Cloudinary cloudinary = new Cloudinary(ObjectUtils.asMap(
                    "cloud_name", cloudName,
                    "api_key", apiKey,
                    "api_secret", apiSecret));

            // Gọi Admin API để lấy danh sách file
            com.cloudinary.api.ApiResponse response = cloudinary.api().resources(ObjectUtils.asMap(
                    "resource_type", "video",
                    "type", "upload",
                    "prefix", "aquatrade/videos/", 
                    "max_results", 50
            ));

            List<Map<String, Object>> resources = (List<Map<String, Object>>) response.get("resources");
            List<String> videoUrls = new ArrayList<>();
            if (resources != null) {
                for (Map<String, Object> res : resources) {
                    videoUrls.add((String) res.get("secure_url"));
                }
            }
            return videoUrls;
        } catch (Exception e) {
            e.printStackTrace();
            return Collections.emptyList();
        }
    }
}
