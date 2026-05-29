package com.example.nlu.repo;

import com.example.nlu.entity.Schedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ScheduleRepository extends JpaRepository<Schedule, Long> {

    @Query("SELECT s FROM Schedule s " +
           "JOIN FETCH s.enrollment e " +
           "JOIN FETCH e.course c " +
           "WHERE e.id IN :enrollmentIds")
    List<Schedule> findByEnrollmentIds(@Param("enrollmentIds") List<Long> enrollmentIds);

    /**
     * Tìm các lịch học cùng sinh viên, cùng học kỳ/năm học, cùng thứ, cùng ca.
     * Loại trừ chính schedule đang được cập nhật (excludeScheduleId).
     */
    @Query("SELECT s FROM Schedule s " +
           "JOIN s.enrollment e " +
           "WHERE e.student.id = :studentId " +
           "AND e.academicYear = :academicYear " +
           "AND e.semester = :semester " +
           "AND s.dayOfWeek = :dayOfWeek " +
           "AND s.period = :period " +
           "AND s.id <> :excludeScheduleId")
    List<Schedule> findConflicts(
            @Param("studentId") Long studentId,
            @Param("academicYear") String academicYear,
            @Param("semester") String semester,
            @Param("dayOfWeek") int dayOfWeek,
            @Param("period") int period,
            @Param("excludeScheduleId") Long excludeScheduleId);
}
