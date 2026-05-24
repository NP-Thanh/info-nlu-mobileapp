package com.example.nlu.scheduler;

import com.example.nlu.entity.Student;
import com.example.nlu.entity.User;
import com.example.nlu.repo.StudentRepository;
import com.example.nlu.service.NotificationService;
import com.example.nlu.service.ScheduleService;
import com.example.nlu.service.ScheduleService.DailyScheduleMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;

/**
 * Mỗi ngày 7:00 sáng (giờ VN) gửi thông báo lịch học trong ngày cho từng sinh viên.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class DailyScheduleNotificationScheduler {

    private final StudentRepository studentRepository;
    private final ScheduleService scheduleService;
    private final NotificationService notificationService;

    @Value("${app.schedule-notification.enabled:true}")
    private boolean enabled;

    @Scheduled(
            cron = "${app.schedule-notification.cron:0 0 7 * * *}",
            zone = "${app.schedule-notification.timezone:Asia/Ho_Chi_Minh}"
    )
    public void sendDailyScheduleNotifications() {
        if (!enabled) {
            return;
        }
        ZoneId zone = ZoneId.of("Asia/Ho_Chi_Minh");
        LocalDate today = LocalDate.now(zone);
        log.info("Bắt đầu gửi thông báo lịch học ngày {}", today);

        List<Student> students = studentRepository.findAll();
        int sent = 0;
        for (Student student : students) {
            User user = student.getUser();
            if (user == null) continue;
            try {
                DailyScheduleMessage message =
                        scheduleService.buildDailyScheduleMessage(student.getStudentCode(), today);
                notificationService.createAndPush(
                        user,
                        message.title(),
                        message.content(),
                        "schedule");
                sent++;
            } catch (Exception e) {
                log.warn("Lỗi thông báo lịch cho {}: {}", student.getStudentCode(), e.getMessage());
            }
        }
        log.info("Hoàn tất thông báo lịch học: {} sinh viên", sent);
    }
}
