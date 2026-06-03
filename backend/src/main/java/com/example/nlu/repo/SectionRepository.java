package com.example.nlu.repo;

import com.example.nlu.entity.Section;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SectionRepository extends JpaRepository<Section, Long> {

    /** Tìm section theo course + semester + year + isLab */
    @Query("""
           SELECT s FROM Section s
           JOIN FETCH s.course c
           WHERE s.course.id = :courseId
             AND s.semester = :semester
             AND s.academicYear = :academicYear
             AND s.isLab = :isLab
           """)
    List<Section> findByCourseAndSemesterAndYear(
            @Param("courseId") Long courseId,
            @Param("semester") String semester,
            @Param("academicYear") String academicYear,
            @Param("isLab") Boolean isLab);

    /** Kiểm tra đã tồn tại section chưa */
    boolean existsByCourse_IdAndSemesterAndAcademicYearAndIsLab(
            Long courseId, String semester, String academicYear, Boolean isLab);

    /** Tìm section LT (isLab=false) theo course + semester + year */
    Optional<Section> findTopByCourse_IdAndSemesterAndAcademicYearAndIsLabFalseOrderByIdDesc(
            Long courseId, String semester, String academicYear);

    /** Tìm section LT (isLab=false) mới nhất theo course (không cần term) */
    Optional<Section> findTopByCourse_IdAndIsLabFalseOrderByIdDesc(Long courseId);
}
