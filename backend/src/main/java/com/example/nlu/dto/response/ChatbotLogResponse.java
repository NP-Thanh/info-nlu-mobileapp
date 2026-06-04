package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ChatbotLogResponse {
    private Long id;
    private String question;
    private String answer;
    private String createdAt;
    private Boolean isFlagged;
    // Admin fields (null khi student tự xem lịch sử)
    private String studentCode;
    private String studentName;
}
