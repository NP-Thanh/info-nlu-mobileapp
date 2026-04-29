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
}
