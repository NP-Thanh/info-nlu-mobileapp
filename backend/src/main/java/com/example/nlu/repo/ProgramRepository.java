package com.example.nlu.repo;

import com.example.nlu.entity.Program;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ProgramRepository extends JpaRepository<Program, Long> {

    @Query("""
        SELECT DISTINCT p.faculty FROM Program p
        WHERE p.faculty IS NOT NULL AND p.faculty <> ''
        ORDER BY p.faculty
        """)
    List<String> findDistinctFaculties();

    @Query("""
        SELECT DISTINCT p.major FROM Program p
        WHERE LOWER(p.faculty) = LOWER(:faculty)
          AND p.major IS NOT NULL AND p.major <> ''
        ORDER BY p.major
        """)
    List<String> findDistinctMajorsByFaculty(@Param("faculty") String faculty);

    @Query("""
        SELECT DISTINCT p.specialization FROM Program p
        WHERE LOWER(p.faculty) = LOWER(:faculty)
          AND LOWER(p.major) = LOWER(:major)
          AND p.specialization IS NOT NULL AND p.specialization <> ''
        ORDER BY p.specialization
        """)
    List<String> findDistinctSpecializationsByFacultyAndMajor(
            @Param("faculty") String faculty,
            @Param("major") String major
    );

    @Query("""
        SELECT p FROM Program p
        WHERE LOWER(p.faculty) = LOWER(:faculty)
          AND LOWER(p.major) = LOWER(:major)
          AND LOWER(p.specialization) = LOWER(:specialization)
        """)
    Optional<Program> findByFacultyMajorSpecialization(
            @Param("faculty") String faculty,
            @Param("major") String major,
            @Param("specialization") String specialization
    );
}
