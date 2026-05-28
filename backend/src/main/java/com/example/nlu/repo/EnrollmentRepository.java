package com.example.nlu.repo;

import com.example.nlu.entity.Enrollment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface EnrollmentRepository extends JpaRepository<Enrollment, Long> {

    @Query("SELECT e FROM Enrollment e " +
           "JOIN FETCH e.course c " +
           "WHERE e.student.studentCode = :studentCode " +
           "AND e.academicYear = :academicYear " +
           "AND e.semester = :semester")
    List<Enrollment> findByStudentAndSemester(
            @Param("studentCode") String studentCode,
            @Param("academicYear") String academicYear,
            @Param("semester") String semester);

    @Query("SELECT e FROM Enrollment e " +
           "JOIN FETCH e.course c " +
           "WHERE e.student.studentCode = :studentCode")
    List<Enrollment> findAllByStudentCode(@Param("studentCode") String studentCode);

    @Query("SELECT DISTINCT e.semester, e.academicYear FROM Enrollment e " +
           "WHERE e.student.studentCode = :studentCode " +
           "ORDER BY e.academicYear DESC, e.semester DESC")
    List<Object[]> findDistinctSemestersByStudent(@Param("studentCode") String studentCode);

    Optional<Enrollment> findTopByStudent_IdAndCourse_IdAndIsLabFalseOrderByIdDesc(Long studentId, Long courseId);

    Optional<Enrollment> findTopByStudent_IdAndCourse_IdAndAcademicYearAndSemesterAndIsLabFalseOrderByIdDesc(
            Long studentId,
            Long courseId,
            String academicYear,
            String semester
    );

    @Query("""
           SELECT DISTINCT e.semester, e.academicYear
           FROM Enrollment e
           WHERE e.student.studentCode = :studentCode
           ORDER BY e.academicYear DESC, e.semester DESC
           """)
    List<Object[]> findTermsByStudentCode(@Param("studentCode") String studentCode);

    @Query("""
           SELECT e
           FROM Enrollment e
           JOIN FETCH e.course c
           WHERE e.student.studentCode = :studentCode
             AND e.academicYear = :academicYear
             AND e.semester = :semester
             AND (:keyword IS NULL
                  OR LOWER(c.courseCode) LIKE LOWER(CONCAT('%', :keyword, '%'))
                  OR LOWER(c.courseName) LIKE LOWER(CONCAT('%', :keyword, '%')))
           ORDER BY c.courseCode
           """)
    List<Enrollment> findCoursesByStudentAndTerm(
            @Param("studentCode") String studentCode,
            @Param("academicYear") String academicYear,
            @Param("semester") String semester,
            @Param("keyword") String keyword
    );

    List<Enrollment> findAllByStudent_Id(Long studentId);
}
