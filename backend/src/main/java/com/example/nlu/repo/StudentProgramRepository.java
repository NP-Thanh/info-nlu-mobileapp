package com.example.nlu.repo;

import com.example.nlu.entity.StudentProgram;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface StudentProgramRepository extends JpaRepository<StudentProgram, Long> {
    Optional<StudentProgram> findFirstByStudent_StudentCode(String studentCode);

    Optional<StudentProgram> findFirstByStudent_Id(Long studentId);

    List<StudentProgram> findAllByStudent_Id(Long studentId);

    /** Lấy danh sách student_id theo lớp và/hoặc khoa */
    @Query("""
        SELECT sp.student.id FROM StudentProgram sp
        WHERE (:className IS NULL OR :className = '' OR LOWER(sp.className) = LOWER(:className))
          AND (:faculty   IS NULL OR :faculty   = '' OR LOWER(sp.program.faculty) = LOWER(:faculty))
    """)
    List<Long> findStudentIdsByClassNameAndFaculty(
            @Param("className") String className,
            @Param("faculty") String faculty
    );

    @Query("""
        SELECT DISTINCT sp.className FROM StudentProgram sp
        WHERE sp.className IS NOT NULL AND sp.className <> ''
          AND (:keyword IS NULL OR :keyword = '' OR LOWER(sp.className) LIKE LOWER(CONCAT('%', :keyword, '%')))
        ORDER BY sp.className
        """)
    List<String> suggestClassNames(@Param("keyword") String keyword);

    @Query("""
        SELECT DISTINCT p.faculty FROM StudentProgram sp
        JOIN sp.program p
        WHERE p.faculty IS NOT NULL AND p.faculty <> ''
          AND (:keyword IS NULL OR :keyword = '' OR LOWER(p.faculty) LIKE LOWER(CONCAT('%', :keyword, '%')))
        ORDER BY p.faculty
        """)
    List<String> suggestFaculties(@Param("keyword") String keyword);
}
