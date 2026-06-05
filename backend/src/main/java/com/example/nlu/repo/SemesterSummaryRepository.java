package com.example.nlu.repo;

import com.example.nlu.entity.SemesterSummary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SemesterSummaryRepository extends JpaRepository<SemesterSummary, Long> {

    @Query("""
        SELECT ss FROM SemesterSummary ss
        WHERE ss.student.studentCode = :studentCode
          AND ss.academicYear = :academicYear
          AND ss.semester = :semester
    """)
    Optional<SemesterSummary> findByStudentAndSemester(
            @Param("studentCode") String studentCode,
            @Param("academicYear") String academicYear,
            @Param("semester") String semester
    );

    @Query("""
        SELECT ss FROM SemesterSummary ss
        WHERE ss.student.id = :studentId
    """)
    List<SemesterSummary> findAllByStudentId(@Param("studentId") Long studentId);

    @Query("""
        SELECT ss FROM SemesterSummary ss
        WHERE ss.student.studentCode = :studentCode
        ORDER BY ss.academicYear DESC, ss.semester DESC
    """)
    List<SemesterSummary> findAllByStudentCode(@Param("studentCode") String studentCode);
}
