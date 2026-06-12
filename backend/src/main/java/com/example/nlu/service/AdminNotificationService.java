package com.example.nlu.service;

import com.example.nlu.dto.request.AdminDeleteNotificationGroupRequest;
import com.example.nlu.dto.request.AdminSendNotificationRequest;
import com.example.nlu.dto.response.AdminNotificationDetailResponse;
import com.example.nlu.dto.response.AdminNotificationDetailResponse.RecipientInfo;
import com.example.nlu.dto.response.AdminNotificationGroupResponse;
import com.example.nlu.entity.Notification;
import com.example.nlu.entity.Student;
import com.example.nlu.repo.NotificationRepository;
import com.example.nlu.repo.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminNotificationService {

    private final NotificationRepository notificationRepository;
    private final StudentRepository studentRepository;
    private final NotificationService notificationService;

    /** Danh sách thông báo đại diện cho admin (1 mỗi nhóm). */
    public List<AdminNotificationGroupResponse> getGroupedNotifications(
            String content, String type, String title) {

        return notificationRepository
                .findGroupedNotifications(content, type, title)
                .stream()
                .map(n -> {
                    long count = notificationRepository.countByGroup(n.getTitle(), n.getContent(), n.getType());
                    return AdminNotificationGroupResponse.builder()
                            .representativeId(n.getId())
                            .title(n.getTitle())
                            .content(n.getContent())
                            .type(n.getType())
                            .recipientCount(count)
                            .createdAt(n.getCreatedAt())
                            .build();
                })
                .toList();
    }

    /** Chi tiết 1 nhóm thông báo + danh sách sinh viên đã nhận. */
    public AdminNotificationDetailResponse getGroupDetail(String title, String content, String type) {
        List<Notification> notifications = notificationRepository.findByGroup(title, content, type);
        if (notifications.isEmpty()) {
            throw new IllegalArgumentException("Không tìm thấy thông báo");
        }
        Notification first = notifications.get(0);

        List<RecipientInfo> recipients = notifications.stream().map(n -> {
            Student student = studentRepository.findByUser_Id(n.getUser().getId()).orElse(null);
            return RecipientInfo.builder()
                    .userId(n.getUser().getId())
                    .studentId(student != null ? student.getId() : null)
                    .studentCode(student != null ? student.getStudentCode() : null)
                    .fullName(student != null ? student.getFullName() : n.getUser().getUsername())
                    .isRead(Boolean.TRUE.equals(n.getIsRead()))
                    .build();
        }).toList();

        return AdminNotificationDetailResponse.builder()
                .title(first.getTitle())
                .content(first.getContent())
                .type(first.getType())
                .createdAt(first.getCreatedAt())
                .recipients(recipients)
                .build();
    }

    /** Gửi thông báo mới đến danh sách sinh viên (theo student.id). */
    @Transactional
    public int sendNotifications(AdminSendNotificationRequest request) {
        if (request.getStudentIds() == null || request.getStudentIds().isEmpty()) {
            throw new IllegalArgumentException("Phải chọn ít nhất 1 sinh viên");
        }
        if (request.getTitle() == null || request.getTitle().isBlank()) {
            throw new IllegalArgumentException("Tiêu đề không được để trống");
        }
        if (request.getContent() == null || request.getContent().isBlank()) {
            throw new IllegalArgumentException("Nội dung không được để trống");
        }
        if (request.getType() == null || request.getType().isBlank()) {
            throw new IllegalArgumentException("Loại thông báo không được để trống");
        }

        int count = 0;
        for (Long studentId : request.getStudentIds()) {
            Student student = studentRepository.findById(studentId).orElse(null);
            if (student == null || student.getUser() == null) continue;
            notificationService.createAndPush(
                    student.getUser(),
                    request.getTitle(),
                    request.getContent(),
                    request.getType()
            );
            count++;
        }
        return count;
    }

    /** Soft-delete theo nhóm (title + content + type). */
    @Transactional
    public void deleteGroups(AdminDeleteNotificationGroupRequest request) {
        if (request.getGroups() == null || request.getGroups().isEmpty()) return;
        for (var key : request.getGroups()) {
            List<Notification> list = notificationRepository.findAllByGroupForDelete(
                    key.getTitle(), key.getContent(), key.getType());
            list.forEach(n -> n.setIsDeleted(true));
            notificationRepository.saveAll(list);
        }
    }

    /** Các type hiện có để filter. */
    public List<String> getDistinctTypes() {
        return notificationRepository.findDistinctTypes();
    }

    /** Các title hiện có để filter. */
    public List<String> getDistinctTitles() {
        return notificationRepository.findDistinctTitles();
    }
}
