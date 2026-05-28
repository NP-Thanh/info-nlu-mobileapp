package com.example.nlu.repo;

import com.example.nlu.entity.Student;
import com.example.nlu.entity.StudentStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface StudentRepository extends JpaRepository<Student, Long> {
    Optional<Student> findByStudentCode(String studentCode);
    Optional<Student> findByUser_Id(Long userId);

    /**
     * Tìm kiếm sinh viên theo tên hoặc mã số sinh viên.
     * Hỗ trợ tìm kiếm nhiều từ khóa (ví dụ: "Nguyễn Phúc" sẽ khớp nếu fullName chứa cả "Nguyễn" và "Phúc").
     */
    @Query("""
        SELECT s FROM Student s
        WHERE (:keyword IS NULL OR :keyword = ''
               OR (LOWER(s.fullName) LIKE LOWER(CONCAT('%', :keyword, '%'))
                   OR LOWER(s.studentCode) LIKE LOWER(CONCAT('%', :keyword, '%'))))
          AND (:startYear IS NULL OR s.startYear = :startYear)
          AND (:status IS NULL OR s.status = :status)
    """)
    List<Student> searchStudents(
            @Param("keyword") String keyword,
            @Param("startYear") Integer startYear,
            @Param("status") StudentStatus status
    );

    @Query("""
        SELECT DISTINCT s.startYear FROM Student s
        WHERE s.startYear IS NOT NULL
        ORDER BY s.startYear DESC
        """)
    List<Integer> findDistinctStartYears();
}
