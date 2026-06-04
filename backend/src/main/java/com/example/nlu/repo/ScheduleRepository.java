package com.example.nlu.repo;

import com.example.nlu.entity.Schedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ScheduleRepository extends JpaRepository<Schedule, Long> {

    /** Lấy schedules theo section ids (cho student TKB) */
    @Query("SELECT s FROM Schedule s " +
           "JOIN FETCH s.section sec " +
           "JOIN FETCH sec.course c " +
           "WHERE sec.id IN :sectionIds " +
           "AND (s.isDeleted = false OR s.isDeleted IS NULL)")
    List<Schedule> findBySectionIds(@Param("sectionIds") List<Long> sectionIds);

    /** Admin list: tất cả schedule chưa xóa */
    @Query("SELECT s FROM Schedule s " +
           "JOIN FETCH s.section sec " +
           "JOIN FETCH sec.course c " +
           "WHERE (s.isDeleted = false OR s.isDeleted IS NULL)")
    List<Schedule> findAllActiveWithSection();

    /** Lấy chi tiết 1 schedule theo id */
    @Query("SELECT s FROM Schedule s " +
           "JOIN FETCH s.section sec " +
           "JOIN FETCH sec.course c " +
           "WHERE s.id = :id")
    Optional<Schedule> findByIdWithDetails(@Param("id") Long id);

    /** Kiểm tra trùng lịch học (cùng môn, kỳ, năm, ngày, ca, phòng) */
    @Query("SELECT COUNT(s) > 0 FROM Schedule s " +
           "JOIN s.section sec " +
           "WHERE sec.course.id = :courseId " +
           "AND sec.semester = :semester " +
           "AND sec.academicYear = :academicYear " +
           "AND s.dayOfWeek = :dayOfWeek " +
           "AND s.period = :period " +
           "AND (:room IS NULL OR s.room = :room) " +
           "AND (:excludeId IS NULL OR s.id <> :excludeId) " +
           "AND (s.isDeleted = false OR s.isDeleted IS NULL)")
    boolean existsDuplicateSchedule(
            @Param("courseId") Long courseId,
            @Param("semester") String semester,
            @Param("academicYear") String academicYear,
            @Param("dayOfWeek") int dayOfWeek,
            @Param("period") int period,
            @Param("room") String room,
            @Param("excludeId") Long excludeId);

    /** Kiểm tra giảng viên trùng ca */
    @Query("SELECT COUNT(s) > 0 FROM Schedule s " +
           "JOIN s.section sec " +
           "WHERE s.lecturer = :lecturer " +
           "AND sec.semester = :semester " +
           "AND sec.academicYear = :academicYear " +
           "AND s.dayOfWeek = :dayOfWeek " +
           "AND s.period = :period " +
           "AND (:excludeId IS NULL OR s.id <> :excludeId) " +
           "AND (s.isDeleted = false OR s.isDeleted IS NULL)")
    boolean existsLecturerConflict(
            @Param("lecturer") String lecturer,
            @Param("semester") String semester,
            @Param("academicYear") String academicYear,
            @Param("dayOfWeek") int dayOfWeek,
            @Param("period") int period,
            @Param("excludeId") Long excludeId);

    /** Các năm học phân biệt */
    @Query("SELECT DISTINCT sec.academicYear FROM Schedule s " +
           "JOIN s.section sec " +
           "WHERE (s.isDeleted = false OR s.isDeleted IS NULL) " +
           "ORDER BY sec.academicYear DESC")
    List<String> findDistinctAcademicYears();

    /** Lấy schedules theo một sectionId (cho section detail) */
    @Query("SELECT s FROM Schedule s " +
           "WHERE s.section.id = :sectionId " +
           "AND (s.isDeleted = false OR s.isDeleted IS NULL) " +
           "ORDER BY s.dayOfWeek, s.period")
    List<Schedule> findActiveBySectionId(@Param("sectionId") Long sectionId);
}
