package com.example.nlu.service;

import com.example.nlu.dto.response.GradeItemResponse;
import com.example.nlu.dto.response.GradeResponse;
import com.example.nlu.dto.response.SemesterSummaryResponse;
import com.example.nlu.entity.Grade;
import com.example.nlu.entity.SemesterSummary;
import com.example.nlu.repo.GradeRepository;
import com.example.nlu.repo.SemesterSummaryRepository;
import com.example.nlu.repo.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class GradeService {

    private final GradeRepository gradeRepository;
    private final StudentRepository studentRepository;
    private final SemesterSummaryRepository semesterSummaryRepository;

    public GradeResponse getGrades(String studentCode, String academicYear, String semester) {
        // Validate student exists
        studentRepository.findByStudentCode(studentCode)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy sinh viên"));

        List<Grade> grades = gradeRepository.findByStudentAndSemester(studentCode, academicYear, semester);

        List<GradeItemResponse> items = grades.stream()
                .map(g -> GradeItemResponse.builder()
                        .courseCode(g.getEnrollment().getCourse().getCourseCode())
                        .courseName(g.getEnrollment().getCourse().getCourseName())
                        .credits(g.getEnrollment().getCourse().getCredits())
                        .processScore(g.getProcessScore())
                        .examScore(g.getExamScore())
                        .finalScore10(g.getFinalScore10())
                        .finalScore4(g.getFinalScore4())
                        .result(g.getResult())
                        .build())
                .toList();

        return GradeResponse.builder()
                .semester(semester)
                .academicYear(academicYear)
                .grades(items)
                .build();
    }

    public SemesterSummaryResponse getSemesterSummary(String studentCode, String academicYear, String semester) {
        studentRepository.findByStudentCode(studentCode)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy sinh viên"));

        SemesterSummary ss = semesterSummaryRepository
                .findByStudentAndSemester(studentCode, academicYear, semester)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy dữ liệu học kỳ"));

        return SemesterSummaryResponse.builder()
                .semester(ss.getSemester())
                .academicYear(ss.getAcademicYear())
                .gpa10(ss.getGpa10())
                .gpa4(ss.getGpa4())
                .cumulativeGpa10(ss.getCumulativeGpa10())
                .cumulativeGpa4(ss.getCumulativeGpa4())
                .build();
    }
}
