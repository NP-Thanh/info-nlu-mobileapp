package com.example.nlu.service;

import com.example.nlu.dto.request.UpdateScheduleRequest;
import com.example.nlu.dto.response.ScheduleResponse;
import com.example.nlu.entity.Schedule;
import com.example.nlu.entity.Student;
import com.example.nlu.repo.ScheduleRepository;
import com.example.nlu.repo.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminScheduleService {

    private final StudentRepository studentRepository;
    private final ScheduleRepository scheduleRepository;
    private final ScheduleService scheduleService;

    public ScheduleResponse getLatestSchedule(Long studentId) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sinh viên"));
        return scheduleService.getLatestSchedule(student.getStudentCode());
    }

    @Transactional
    public ScheduleResponse updateSchedule(Long scheduleId, UpdateScheduleRequest req) {
        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lịch học"));

        if (req.getRoom() != null) schedule.setRoom(req.getRoom());
        if (req.getLecturer() != null) schedule.setLecturer(req.getLecturer());
        int newDay = req.getDayOfWeek() != null ? req.getDayOfWeek() : schedule.getDayOfWeek();
        int newPeriod = req.getPeriod() != null ? req.getPeriod() : schedule.getPeriod();

        if (req.getDayOfWeek() != null) {
            if (req.getDayOfWeek() < 2 || req.getDayOfWeek() > 8)
                throw new IllegalArgumentException("Thứ trong tuần không hợp lệ (2-8)");
        }
        if (req.getPeriod() != null) {
            if (req.getPeriod() < 1 || req.getPeriod() > 4)
                throw new IllegalArgumentException("Ca học không hợp lệ (1-4)");
        }

        // Kiểm tra trùng ca học trong cùng học kỳ
        Long studentId = schedule.getEnrollment().getStudent().getId();
        String academicYear = schedule.getEnrollment().getAcademicYear();
        String semester = schedule.getEnrollment().getSemester();
        List<Schedule> conflicts = scheduleRepository.findConflicts(studentId, academicYear, semester, newDay, newPeriod, scheduleId);
        if (!conflicts.isEmpty()) {
            Schedule conflict = conflicts.get(0);
            String conflictName = conflict.getEnrollment().getCourse().getCourseName();
            throw new IllegalArgumentException(
                    "Ca " + newPeriod + " vào " + dayLabel(newDay) + " đã bị trùng với môn \"" + conflictName + "\""
            );
        }

        schedule.setDayOfWeek(newDay);
        schedule.setPeriod(newPeriod);
        scheduleRepository.save(schedule);

        String studentCode = schedule.getEnrollment().getStudent().getStudentCode();
        var enrollment = schedule.getEnrollment();
        return scheduleService.getSchedule(
                studentCode,
                enrollment.getAcademicYear(),
                enrollment.getSemester()
        );
    }

    @Transactional
    public void deleteSchedule(Long scheduleId) {
        if (!scheduleRepository.existsById(scheduleId))
            throw new IllegalArgumentException("Không tìm thấy lịch học");
        scheduleRepository.deleteById(scheduleId);
    }

    private String dayLabel(int day) {
        return switch (day) {
            case 2 -> "Thứ 2";
            case 3 -> "Thứ 3";
            case 4 -> "Thứ 4";
            case 5 -> "Thứ 5";
            case 6 -> "Thứ 6";
            case 7 -> "Thứ 7";
            case 8 -> "Chủ nhật";
            default -> "Thứ " + day;
        };
    }
}
