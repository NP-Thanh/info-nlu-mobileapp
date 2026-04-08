package com.example.nlu.service;

import com.example.nlu.dto.response.StudentInfoResponse;
import com.example.nlu.entity.Student;
import com.example.nlu.entity.StudentProgram;
import com.example.nlu.repo.StudentProgramRepository;
import com.example.nlu.repo.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.format.DateTimeFormatter;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class StudentService {

    private final StudentRepository studentRepository;
    private final StudentProgramRepository studentProgramRepository;

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    public StudentInfoResponse getStudentInfo(String studentCode) {
        Student s = studentRepository.findByStudentCode(studentCode)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy sinh viên"));

        Optional<StudentProgram> spOpt = studentProgramRepository
                .findFirstByStudent_StudentCode(studentCode);

        String academicYear = spOpt.map(sp ->
                sp.getStartYear() + " - " + sp.getEndYear()).orElse(null);

        return StudentInfoResponse.builder()
                .studentCode(s.getStudentCode())
                .fullName(s.getFullName())
                .status(s.getStatus())
                .dateOfBirth(s.getDateOfBirth() != null ? s.getDateOfBirth().format(DATE_FMT) : null)
                .gender(s.getGender())
                .phone(s.getPhone())
                .idCard(s.getCccd())
                .email(s.getUser() != null ? s.getUser().getEmail() : null)
                .birthPlace(s.getPlaceOfBirth())
                .ethnicity(s.getEthnicity())
                .religion("Không")
                .nationality("Việt Nam")
                .major(spOpt.map(sp -> sp.getProgram().getMajor()).orElse(null))
                .classCode(spOpt.map(StudentProgram::getClassName).orElse(null))
                .faculty(spOpt.map(sp -> sp.getProgram().getFaculty()).orElse(null))
                .academicYear(academicYear)
                .degreeType(spOpt.map(sp -> sp.getProgram().getEducationType()).orElse(null))
                .build();
    }
}
