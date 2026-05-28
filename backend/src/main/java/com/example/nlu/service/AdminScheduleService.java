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
        if (req.getDayOfWeek() != null) {
            if (req.getDayOfWeek() < 2 || req.getDayOfWeek() > 8)
                throw new IllegalArgumentException("Thứ trong tuần không hợp lệ (2-8)");
            schedule.setDayOfWeek(req.getDayOfWeek());
        }
        if (req.getPeriod() != null) {
            if (req.getPeriod() < 1 || req.getPeriod() > 4)
                throw new IllegalArgumentException("Ca học không hợp lệ (1-4)");
            schedule.setPeriod(req.getPeriod());
        }
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
}
