package com.example.nlu.repo;

import com.example.nlu.entity.Grade;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface GradeRepository extends JpaRepository<Grade, Long> {

    /** Lấy điểm theo enrollment_id */
    Optional<Grade> findByEnrollment_Id(Long enrollmentId);

    /** Lấy tất cả điểm của một sinh viên trong một học kỳ/năm học */
    @Query("""
        SELECT g FROM Grade g
        JOIN FETCH g.enrollment e
        JOIN FETCH e.section s
        JOIN FETCH s.course c
        WHERE e.student.studentCode = :studentCode
          AND s.academicYear = :academicYear
          AND s.semester = :semester
          AND s.isLab = false
    """)
    List<Grade> findByStudentAndSemester(
            @Param("studentCode") String studentCode,
            @Param("academicYear") String academicYear,
            @Param("semester") String semester
    );

    /** Lấy tất cả điểm của student qua enrollment ids */
    @Query("""
        SELECT g FROM Grade g
        JOIN FETCH g.enrollment e
        JOIN FETCH e.section s
        JOIN FETCH s.course c
        WHERE e.id IN :enrollmentIds
    """)
    List<Grade> findAllByEnrollmentIds(@Param("enrollmentIds") List<Long> enrollmentIds);
}
