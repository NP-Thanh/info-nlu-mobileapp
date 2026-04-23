package com.example.nlu.repo;

import com.example.nlu.entity.Enrollment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

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
}
