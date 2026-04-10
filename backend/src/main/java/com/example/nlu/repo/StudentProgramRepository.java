package com.example.nlu.repo;

import com.example.nlu.entity.StudentProgram;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface StudentProgramRepository extends JpaRepository<StudentProgram, Long> {
    Optional<StudentProgram> findFirstByStudent_StudentCode(String studentCode);
}
