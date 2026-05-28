package com.example.nlu.service;

import com.example.nlu.entity.Program;
import com.example.nlu.repo.ProgramRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminProgramService {

    private final ProgramRepository programRepository;

    public List<String> getFaculties() {
        return programRepository.findDistinctFaculties();
    }

    public List<String> getMajors(String faculty) {
        if (isBlank(faculty)) throw new IllegalArgumentException("Vui lòng chọn khoa trước");
        return programRepository.findDistinctMajorsByFaculty(faculty.trim());
    }

    public List<String> getSpecializations(String faculty, String major) {
        if (isBlank(faculty)) throw new IllegalArgumentException("Vui lòng chọn khoa trước");
        if (isBlank(major)) throw new IllegalArgumentException("Vui lòng chọn ngành trước");
        return programRepository.findDistinctSpecializationsByFacultyAndMajor(faculty.trim(), major.trim());
    }

    public Map<String, Object> resolveProgramId(String faculty, String major, String specialization) {
        Program program = programRepository
                .findByFacultyMajorSpecialization(faculty.trim(), major.trim(), specialization.trim())
                .orElseThrow(() -> new IllegalArgumentException(
                        "Không tìm thấy chương trình đào tạo phù hợp"));
        return Map.of(
                "programId", program.getId(),
                "faculty", program.getFaculty(),
                "major", program.getMajor(),
                "specialization", program.getSpecialization(),
                "educationType", program.getEducationType() != null ? program.getEducationType() : ""
        );
    }

    private boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
