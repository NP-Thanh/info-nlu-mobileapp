package com.example.nlu.dto.request;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class AdminSendNotificationRequest {
    private String title;
    private String content;
    private String type;
    private List<Long> studentIds; // danh sách student.id (không phải user.id)
}
