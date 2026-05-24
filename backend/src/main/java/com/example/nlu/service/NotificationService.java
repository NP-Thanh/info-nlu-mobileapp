package com.example.nlu.service;

import com.example.nlu.dto.response.NotificationResponse;
import com.example.nlu.entity.Notification;
import com.example.nlu.entity.User;
import com.example.nlu.repo.NotificationRepository;
import com.example.nlu.repo.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final FcmPushService fcmPushService;

    public List<NotificationResponse> getNotifications(String username) {
        User user = requireUser(username);
        return notificationRepository.findByUser_IdAndIsDeletedFalseOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public List<NotificationResponse> getUnreadNotifications(String username) {
        User user = requireUser(username);
        return notificationRepository.findByUser_IdAndIsReadFalseAndIsDeletedFalseOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public NotificationResponse markAsRead(String username, Long id) {
        Notification notification = requireOwnedNotification(username, id);
        notification.setIsRead(true);
        return toResponse(notificationRepository.save(notification));
    }

    @Transactional
    public void markAsRead(String username, List<Long> ids) {
        User user = requireUser(username);
        List<Notification> notifications = notificationRepository
                .findByIdInAndUser_IdAndIsDeletedFalse(ids, user.getId());
        notifications.forEach(n -> n.setIsRead(true));
        notificationRepository.saveAll(notifications);
    }

    @Transactional
    public void markAllAsRead(String username) {
        User user = requireUser(username);
        List<Notification> unread = notificationRepository
                .findByUser_IdAndIsReadFalseAndIsDeletedFalseOrderByCreatedAtDesc(user.getId());
        unread.forEach(n -> n.setIsRead(true));
        notificationRepository.saveAll(unread);
    }

    @Transactional
    public void softDelete(String username, Long id) {
        Notification notification = requireOwnedNotification(username, id);
        notification.setIsDeleted(true);
        notificationRepository.save(notification);
    }

    /**
     * Tạo thông báo trong DB và gửi push FCM tới thiết bị của user (nếu đã cấu hình Firebase).
     */
    @Transactional
    public NotificationResponse createAndPush(User user, String title, String content, String type) {
        Notification notification = new Notification();
        notification.setUser(user);
        notification.setTitle(title);
        notification.setContent(content);
        notification.setType(type);
        notification.setIsRead(false);
        notification.setIsDeleted(false);
        notification.setCreatedAt(LocalDateTime.now());
        notification = notificationRepository.save(notification);

        Map<String, String> data = new HashMap<>();
        data.put("type", type != null ? type : "general");
        data.put("notificationId", String.valueOf(notification.getId()));

        fcmPushService.sendToUser(user.getId(), title, content, data);
        return toResponse(notification);
    }

    @Transactional
    public NotificationResponse createAndPush(Long userId, String title, String content, String type) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));
        return createAndPush(user, title, content, type);
    }

    @Transactional
    public void softDelete(String username, List<Long> ids) {
        User user = requireUser(username);
        List<Notification> notifications = notificationRepository
                .findByIdInAndUser_IdAndIsDeletedFalse(ids, user.getId());
        notifications.forEach(n -> n.setIsDeleted(true));
        notificationRepository.saveAll(notifications);
    }

    private User requireUser(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));
    }

    private Notification requireOwnedNotification(String username, Long id) {
        User user = requireUser(username);
        return notificationRepository.findByIdAndUser_IdAndIsDeletedFalse(id, user.getId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy thông báo"));
    }

    private NotificationResponse toResponse(Notification n) {
        return NotificationResponse.builder()
                .id(n.getId())
                .title(n.getTitle())
                .content(n.getContent())
                .type(n.getType())
                .isRead(n.getIsRead())
                .createdAt(n.getCreatedAt())
                .build();
    }
}
