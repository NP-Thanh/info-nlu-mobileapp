package com.example.nlu.repo;

import com.example.nlu.entity.Grade;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface GradeRepository extends JpaRepository<Grade, Long> {

    @Query("""
        SELECT g FROM Grade g
        JOIN FETCH g.enrollment e
        JOIN FETCH e.course c
        WHERE e.student.studentCode = :studentCode
          AND e.academicYear = :academicYear
          AND e.semester = :semester
    """)
    List<Grade> findByStudentAndSemester(
            @Param("studentCode") String studentCode,
            @Param("academicYear") String academicYear,
            @Param("semester") String semester
    );

    @Query("""
        SELECT g FROM Grade g
        JOIN FETCH g.enrollment e
        JOIN FETCH e.course c
        WHERE e.id IN :enrollmentIds
    """)
    List<Grade> findAllByEnrollmentIds(@Param("enrollmentIds") List<Long> enrollmentIds);
}
