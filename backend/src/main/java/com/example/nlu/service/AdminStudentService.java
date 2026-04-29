package com.example.nlu.service;

import com.example.nlu.dto.response.AdminStudentResponse;
import com.example.nlu.entity.Student;
import com.example.nlu.entity.StudentProgram;
import com.example.nlu.repo.StudentProgramRepository;
import com.example.nlu.repo.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminStudentService {

    private final StudentRepository studentRepository;
    private final StudentProgramRepository studentProgramRepository;

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    public List<AdminStudentResponse> getStudents(String keyword,
                                                   String className,
                                                   String faculty,
                                                   Integer startYear) {
        // Lấy danh sách student theo keyword, startYear
        List<Student> students = studentRepository.searchStudents(
                isBlank(keyword) ? null : keyword.trim(),
                startYear
        );

        // Lọc theo lớp, khoa
        if (!isBlank(className) || !isBlank(faculty)) {
            List<Long> validIds = studentProgramRepository.findStudentIdsByClassNameAndFaculty(
                    isBlank(className) ? null : className.trim(),
                    isBlank(faculty) ? null : faculty.trim()
            );
            students = students.stream()
                    .filter(s -> validIds.contains(s.getId()))
                    .collect(Collectors.toList());
        }

        return students.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    private AdminStudentResponse toResponse(Student s) {
        Optional<StudentProgram> spOpt = studentProgramRepository.findFirstByStudent_Id(s.getId());

        return AdminStudentResponse.builder()
                .id(s.getId())
                .studentCode(s.getStudentCode())
                .fullName(s.getFullName())
                .gender(s.getGender())
                .dateOfBirth(s.getDateOfBirth() != null ? s.getDateOfBirth().format(DATE_FMT) : null)
                .phone(s.getPhone())
                .email(s.getUser() != null ? s.getUser().getEmail() : null)
                .status(s.getStatus())
                .startYear(s.getStartYear())
                .className(spOpt.map(StudentProgram::getClassName).orElse(null))
                .faculty(spOpt.map(sp -> sp.getProgram().getFaculty()).orElse(null))
                .major(spOpt.map(sp -> sp.getProgram().getMajor()).orElse(null))
                .specialization(spOpt.map(sp -> sp.getProgram().getSpecialization()).orElse(null))
                .build();
    }

    private boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
