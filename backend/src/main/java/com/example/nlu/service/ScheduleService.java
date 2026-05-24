package com.example.nlu.service;

import com.example.nlu.dto.response.ScheduleItemResponse;
import com.example.nlu.dto.response.ScheduleResponse;
import com.example.nlu.entity.Enrollment;
import com.example.nlu.entity.Schedule;
import com.example.nlu.repo.EnrollmentRepository;
import com.example.nlu.repo.ScheduleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ScheduleService {

    private final EnrollmentRepository enrollmentRepository;
    private final ScheduleRepository scheduleRepository;

    // Ca học cố định
    private static final Map<Integer, String[]> PERIOD_TIMES = Map.of(
        1, new String[]{"07:00", "09:15"},
        2, new String[]{"09:30", "11:45"},
        3, new String[]{"12:30", "14:30"},
        4, new String[]{"14:45", "17:00"}
    );

    /** Lấy TKB học kỳ mới nhất của sinh viên */
    public ScheduleResponse getLatestSchedule(String studentCode) {
        List<Enrollment> all = enrollmentRepository.findAllByStudentCode(studentCode);
        if (all.isEmpty()) return emptyResponse(null, null);

        // Tìm học kỳ mới nhất theo academicYear DESC, semester DESC
        Enrollment latest = all.stream()
                .max(Comparator.comparing(Enrollment::getAcademicYear)
                        .thenComparing(Enrollment::getSemester))
                .orElseThrow();

        return getSchedule(studentCode, latest.getAcademicYear(), latest.getSemester());
    }

    /** Lấy TKB theo học kỳ cụ thể */
    public ScheduleResponse getSchedule(String studentCode, String academicYear, String semester) {
        List<Enrollment> enrollments =
                enrollmentRepository.findByStudentAndSemester(studentCode, academicYear, semester);

        if (enrollments.isEmpty()) return emptyResponse(academicYear, semester);

        // startDate/endDate lấy từ enrollment
        LocalDate startDate = enrollments.stream()
                .map(Enrollment::getStartDate).filter(Objects::nonNull)
                .min(Comparator.naturalOrder()).orElse(null);
        LocalDate endDate = enrollments.stream()
                .map(Enrollment::getEndDate).filter(Objects::nonNull)
                .max(Comparator.naturalOrder()).orElse(null);

        // Lấy schedules theo enrollment ids
        List<Long> enrollmentIds = enrollments.stream()
                .map(Enrollment::getId).collect(Collectors.toList());
        List<Schedule> schedules = scheduleRepository.findByEnrollmentIds(enrollmentIds);

        List<ScheduleItemResponse> items = schedules.stream()
                .sorted(Comparator.comparingInt(Schedule::getDayOfWeek)
                        .thenComparingInt(Schedule::getPeriod))
                .map(this::toItemResponse)
                .collect(Collectors.toList());

        return ScheduleResponse.builder()
                .semester(semester)
                .academicYear(academicYear)
                .startDate(startDate != null ? startDate.toString() : null)
                .endDate(endDate != null ? endDate.toString() : null)
                .items(items)
                .build();
    }

    /** Lấy danh sách tất cả học kỳ */
    public List<ScheduleResponse> getAllSemesters(String studentCode) {
        List<Enrollment> all = enrollmentRepository.findAllByStudentCode(studentCode);

        return all.stream()
                .collect(Collectors.groupingBy(
                        e -> e.getAcademicYear() + "|" + e.getSemester()))
                .entrySet().stream()
                .sorted((a, b) -> b.getKey().compareTo(a.getKey()))
                .map(entry -> {
                    String[] parts = entry.getKey().split("\\|");
                    String ay = parts[0], sem = parts[1];
                    List<Enrollment> group = entry.getValue();

                    LocalDate sd = group.stream().map(Enrollment::getStartDate)
                            .filter(Objects::nonNull).min(Comparator.naturalOrder()).orElse(null);
                    LocalDate ed = group.stream().map(Enrollment::getEndDate)
                            .filter(Objects::nonNull).max(Comparator.naturalOrder()).orElse(null);

                    List<Long> ids = group.stream().map(Enrollment::getId).collect(Collectors.toList());
                    List<ScheduleItemResponse> items = scheduleRepository.findByEnrollmentIds(ids)
                            .stream()
                            .sorted(Comparator.comparingInt(Schedule::getDayOfWeek)
                                    .thenComparingInt(Schedule::getPeriod))
                            .map(this::toItemResponse).collect(Collectors.toList());

                    return ScheduleResponse.builder()
                            .semester(sem).academicYear(ay)
                            .startDate(sd != null ? sd.toString() : null)
                            .endDate(ed != null ? ed.toString() : null)
                            .items(items).build();
                })
                .collect(Collectors.toList());
    }

    private ScheduleItemResponse toItemResponse(Schedule s) {
        String[] times = PERIOD_TIMES.getOrDefault(s.getPeriod(), new String[]{"07:00", "09:15"});
        Enrollment e = s.getEnrollment();
        return ScheduleItemResponse.builder()
                .scheduleId(s.getId())
                .courseName(e.getCourse().getCourseName())
                .courseCode(e.getCourse().getCourseCode())
                .credits(e.getCourse().getCredits())
                .lecturer(s.getLecturer())
                .room(s.getRoom())
                .dayOfWeek(s.getDayOfWeek())
                .period(s.getPeriod())
                .periodStart(times[0])
                .periodEnd(times[1])
                .enrollmentStartDate(e.getStartDate() != null ? e.getStartDate().toString() : null)
                .enrollmentEndDate(e.getEndDate() != null ? e.getEndDate().toString() : null)
                .build();
    }

    private ScheduleResponse emptyResponse(String academicYear, String semester) {
        return ScheduleResponse.builder()
                .semester(semester).academicYear(academicYear)
                .startDate(null).endDate(null)
                .items(List.of()).build();
    }

    /** Thông báo lịch học trong ngày (dùng cho push 7h sáng). */
    public DailyScheduleMessage buildDailyScheduleMessage(String studentCode, LocalDate today) {
        ScheduleResponse schedule = getLatestSchedule(studentCode);
        int dayOfWeek = toScheduleDayOfWeek(today);

        List<ScheduleItemResponse> todayItems = schedule.getItems().stream()
                .filter(item -> Objects.equals(item.getDayOfWeek(), dayOfWeek))
                .filter(item -> isActiveOnDate(item, today))
                .sorted(Comparator.comparingInt(ScheduleItemResponse::getPeriod))
                .toList();

        String dateLabel = today.format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
        String dayName = dayNameVietnamese(today);

        if (todayItems.isEmpty()) {
            return new DailyScheduleMessage(
                    "Lịch học",
                    "Hôm nay (" + dayName + ", " + dateLabel + ") bạn không có lịch học.",
                    false);
        }

        StringBuilder content = new StringBuilder();
        content.append("Hôm nay (").append(dayName).append(", ").append(dateLabel)
                .append(") bạn có ").append(todayItems.size()).append(" buổi học:\n");
        for (ScheduleItemResponse item : todayItems) {
            content.append("• Ca ").append(item.getPeriod())
                    .append(" (").append(item.getPeriodStart()).append("-").append(item.getPeriodEnd()).append("): ")
                    .append(item.getCourseName());
            if (item.getRoom() != null && !item.getRoom().isBlank()) {
                content.append(" — ").append(item.getRoom());
            }
            content.append("\n");
        }
        return new DailyScheduleMessage(
                "Lịch học hôm nay — " + todayItems.size() + " buổi",
                content.toString().trim(),
                true);
    }

    private int toScheduleDayOfWeek(LocalDate date) {
        int javaDow = date.getDayOfWeek().getValue();
        return javaDow == 7 ? 8 : javaDow + 1;
    }

    private boolean isActiveOnDate(ScheduleItemResponse item, LocalDate date) {
        if (item.getEnrollmentStartDate() != null) {
            LocalDate start = LocalDate.parse(item.getEnrollmentStartDate());
            if (date.isBefore(start)) return false;
        }
        if (item.getEnrollmentEndDate() != null) {
            LocalDate end = LocalDate.parse(item.getEnrollmentEndDate());
            if (date.isAfter(end)) return false;
        }
        return true;
    }

    private String dayNameVietnamese(LocalDate date) {
        return switch (date.getDayOfWeek()) {
            case MONDAY -> "Thứ Hai";
            case TUESDAY -> "Thứ Ba";
            case WEDNESDAY -> "Thứ Tư";
            case THURSDAY -> "Thứ Năm";
            case FRIDAY -> "Thứ Sáu";
            case SATURDAY -> "Thứ Bảy";
            case SUNDAY -> "Chủ Nhật";
        };
    }

    public record DailyScheduleMessage(String title, String content, boolean hasClasses) {}
}
