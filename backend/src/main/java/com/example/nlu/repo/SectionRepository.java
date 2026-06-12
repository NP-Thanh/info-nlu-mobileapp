package com.example.nlu.repo;

import com.example.nlu.entity.Section;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SectionRepository extends JpaRepository<Section, Long> {

    /** Tìm section active theo id */
    @Query("SELECT s FROM Section s WHERE s.id = :id AND s.isDeleted = false")
    Optional<Section> findActiveById(@Param("id") Long id);

    /** Tìm section theo course + semester + year + groupNumber + teamNumber (chỉ active) */
    @Query("""
           SELECT s FROM Section s
           JOIN FETCH s.course c
           WHERE s.course.id = :courseId
             AND s.semester = :semester
             AND s.academicYear = :academicYear
             AND s.groupNumber = :groupNumber
             AND s.teamNumber = :teamNumber
             AND s.isDeleted = false
           """)
    List<Section> findByCourseAndSemesterAndYearAndGroup(
            @Param("courseId") Long courseId,
            @Param("semester") String semester,
            @Param("academicYear") String academicYear,
            @Param("groupNumber") Integer groupNumber,
            @Param("teamNumber") Integer teamNumber);

    /** Kiểm tra đã tồn tại section active chưa */
    boolean existsByCourse_IdAndSemesterAndAcademicYearAndGroupNumberAndTeamNumberAndIsDeletedFalse(
            Long courseId, String semester, String academicYear, Integer groupNumber, Integer teamNumber);

    /** Lấy tất cả sections active với course, lọc keyword/semester/academicYear */
    @Query("""
           SELECT s FROM Section s
           JOIN FETCH s.course c
           WHERE s.isDeleted = false
             AND (:courseKeyword IS NULL
                  OR LOWER(c.courseCode) LIKE LOWER(CONCAT('%', :courseKeyword, '%'))
                  OR LOWER(c.courseName) LIKE LOWER(CONCAT('%', :courseKeyword, '%')))
             AND (:semester IS NULL OR s.semester = :semester)
             AND (:academicYear IS NULL OR s.academicYear = :academicYear)
           ORDER BY s.academicYear DESC, s.semester DESC, c.courseCode ASC
           """)
    List<Section> findAllWithFilters(
            @Param("courseKeyword") String courseKeyword,
            @Param("semester") String semester,
            @Param("academicYear") String academicYear);

    /** Các năm học phân biệt từ sections active */
    @Query("SELECT DISTINCT s.academicYear FROM Section s WHERE s.isDeleted = false ORDER BY s.academicYear DESC")
    List<String> findDistinctAcademicYears();
}
