package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class AdminNotificationGroupResponse {
    private Long representativeId;
    private String title;
    private String content;
    private String type;
    private long recipientCount;
    private LocalDateTime createdAt;
}
