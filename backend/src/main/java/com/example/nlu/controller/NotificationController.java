package com.example.nlu.controller;

import com.example.nlu.dto.request.NotificationIdsRequest;
import com.example.nlu.dto.response.NotificationResponse;
import com.example.nlu.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    public ResponseEntity<?> getNotifications(Principal principal) {
        if (principal == null) {
            return ResponseEntity.status(401).body(Map.of("message", "Bạn chưa đăng nhập"));
        }
        try {
            List<NotificationResponse> notifications = notificationService.getNotifications(principal.getName());
            return ResponseEntity.ok(notifications);
        } catch (RuntimeException e) {
            return ResponseEntity.status(404).body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/unread")
    public ResponseEntity<?> getUnreadNotifications(Principal principal) {
        if (principal == null) {
            return ResponseEntity.status(401).body(Map.of("message", "Bạn chưa đăng nhập"));
        }
        try {
            List<NotificationResponse> notifications =
                    notificationService.getUnreadNotifications(principal.getName());
            return ResponseEntity.ok(notifications);
        } catch (RuntimeException e) {
            return ResponseEntity.status(404).body(Map.of("message", e.getMessage()));
        }
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<?> markAsRead(Principal principal, @PathVariable Long id) {
        if (principal == null) {
            return ResponseEntity.status(401).body(Map.of("message", "Bạn chưa đăng nhập"));
        }
        try {
            NotificationResponse response = notificationService.markAsRead(principal.getName(), id);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(404).body(Map.of("message", e.getMessage()));
        }
    }

    @PatchMapping("/read")
    public ResponseEntity<?> markAsReadMany(Principal principal, @RequestBody NotificationIdsRequest request) {
        if (principal == null) {
            return ResponseEntity.status(401).body(Map.of("message", "Bạn chưa đăng nhập"));
        }
        try {
            if (request.getIds() == null || request.getIds().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("message", "Danh sách id không hợp lệ"));
            }
            notificationService.markAsRead(principal.getName(), request.getIds());
            return ResponseEntity.ok(Map.of("message", "Đã đánh dấu đã đọc"));
        } catch (RuntimeException e) {
            return ResponseEntity.status(404).body(Map.of("message", e.getMessage()));
        }
    }

    @PatchMapping("/read-all")
    public ResponseEntity<?> markAllAsRead(Principal principal) {
        if (principal == null) {
            return ResponseEntity.status(401).body(Map.of("message", "Bạn chưa đăng nhập"));
        }
        try {
            notificationService.markAllAsRead(principal.getName());
            return ResponseEntity.ok(Map.of("message", "Đã đánh dấu tất cả là đã đọc"));
        } catch (RuntimeException e) {
            return ResponseEntity.status(404).body(Map.of("message", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteNotification(Principal principal, @PathVariable Long id) {
        if (principal == null) {
            return ResponseEntity.status(401).body(Map.of("message", "Bạn chưa đăng nhập"));
        }
        try {
            notificationService.softDelete(principal.getName(), id);
            return ResponseEntity.ok(Map.of("message", "Đã xóa thông báo"));
        } catch (RuntimeException e) {
            return ResponseEntity.status(404).body(Map.of("message", e.getMessage()));
        }
    }

    @DeleteMapping
    public ResponseEntity<?> deleteNotifications(Principal principal, @RequestBody NotificationIdsRequest request) {
        if (principal == null) {
            return ResponseEntity.status(401).body(Map.of("message", "Bạn chưa đăng nhập"));
        }
        try {
            if (request.getIds() == null || request.getIds().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("message", "Danh sách id không hợp lệ"));
            }
            notificationService.softDelete(principal.getName(), request.getIds());
            return ResponseEntity.ok(Map.of("message", "Đã xóa thông báo"));
        } catch (RuntimeException e) {
            return ResponseEntity.status(404).body(Map.of("message", e.getMessage()));
        }
    }
}
