package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
public class AdminNotificationDetailResponse {
    private String title;
    private String content;
    private String type;
    private LocalDateTime createdAt;
    private List<RecipientInfo> recipients;

    @Getter
    @Builder
    public static class RecipientInfo {
        private Long userId;
        private Long studentId;
        private String studentCode;
        private String fullName;
        private boolean isRead;
    }
}
