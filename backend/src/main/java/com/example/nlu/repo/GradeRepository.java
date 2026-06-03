package com.example.nlu.repo;

import com.example.nlu.entity.Grade;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface GradeRepository extends JpaRepository<Grade, Long> {

    /** Lấy điểm theo student + semester + year (qua enrollment -> section) */
    @Query("""
        SELECT g FROM Grade g
        JOIN FETCH g.section s
        JOIN FETCH s.course c
        JOIN Enrollment e ON e.section.id = s.id
        WHERE e.student.studentCode = :studentCode
          AND s.academicYear = :academicYear
          AND s.semester = :semester
    """)
    List<Grade> findByStudentAndSemester(
            @Param("studentCode") String studentCode,
            @Param("academicYear") String academicYear,
            @Param("semester") String semester
    );

    /** Lấy điểm theo danh sách sectionId */
    @Query("""
        SELECT g FROM Grade g
        JOIN FETCH g.section s
        JOIN FETCH s.course c
        WHERE s.id IN :sectionIds
    """)
    List<Grade> findAllBySectionIds(@Param("sectionIds") List<Long> sectionIds);

    Optional<Grade> findBySection_Id(Long sectionId);
}
