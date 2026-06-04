package com.example.nlu.dto.request;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class AdminDeleteNotificationGroupRequest {
    /** Mỗi phần tử là {title, content, type} xác định 1 nhóm cần xóa */
    private List<NotificationGroupKey> groups;

    @Getter
    @Setter
    public static class NotificationGroupKey {
        private String title;
        private String content;
        private String type;
    }
}
