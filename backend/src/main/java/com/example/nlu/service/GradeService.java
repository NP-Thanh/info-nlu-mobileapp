package com.example.nlu.service;

import com.example.nlu.dto.response.GradeItemResponse;
import com.example.nlu.dto.response.GradeResponse;
import com.example.nlu.dto.response.SemesterSummaryResponse;
import com.example.nlu.entity.Enrollment;
import com.example.nlu.entity.Grade;
import com.example.nlu.entity.SemesterSummary;
import com.example.nlu.repo.EnrollmentRepository;
import com.example.nlu.repo.GradeRepository;
import com.example.nlu.repo.SemesterSummaryRepository;
import com.example.nlu.repo.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
@RequiredArgsConstructor
public class GradeService {

    private final GradeRepository gradeRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final StudentRepository studentRepository;
    private final SemesterSummaryRepository semesterSummaryRepository;

    public List<Map<String, String>> getAvailableSemesters(String studentCode) {
        studentRepository.findByStudentCode(studentCode)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy sinh viên"));

        return enrollmentRepository.findDistinctSemestersByStudent(studentCode)
                .stream()
                .map(row -> Map.of(
                        "semester", (String) row[0],
                        "academicYear", (String) row[1]
                ))
                .toList();
    }

    public GradeResponse getGrades(String studentCode, String academicYear, String semester) {
        studentRepository.findByStudentCode(studentCode)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy sinh viên"));

        List<Enrollment> enrollments =
                enrollmentRepository.findByStudentAndSemester(studentCode, academicYear, semester);

        List<Grade> grades = gradeRepository.findByStudentAndSemester(studentCode, academicYear, semester);

        // Map từ enrollmentId → Grade
        Map<Long, Grade> gradeByEnrollmentId = new HashMap<>();
        for (Grade g : grades) {
            gradeByEnrollmentId.put(g.getEnrollment().getId(), g);
        }

        Map<String, GradeItemResponse> itemByCode = new LinkedHashMap<>();
        for (Enrollment enrollment : enrollments) {
            String code = enrollment.getSection().getCourse().getCourseCode();
            Grade g = gradeByEnrollmentId.get(enrollment.getId());

            GradeItemResponse existing = itemByCode.get(code);
            if (existing == null) {
                itemByCode.put(code, GradeItemResponse.builder()
                        .courseCode(code)
                        .courseName(enrollment.getSection().getCourse().getCourseName())
                        .credits(enrollment.getSection().getCourse().getCredits())
                        .processScore(g != null ? g.getProcessScore() : null)
                        .examScore(g != null ? g.getExamScore() : null)
                        .finalScore10(g != null ? g.getFinalScore10() : null)
                        .finalScore4(g != null ? g.getFinalScore4() : null)
                        .result(g != null ? g.getResult() : null)
                        .build());
            } else if (g != null) {
                boolean existingHasScore = existing.getFinalScore10() != null;
                boolean newIsHigher = existingHasScore
                        && g.getFinalScore10() != null
                        && g.getFinalScore10() > existing.getFinalScore10();
                if (!existingHasScore || newIsHigher) {
                    itemByCode.put(code, GradeItemResponse.builder()
                            .courseCode(code)
                            .courseName(enrollment.getSection().getCourse().getCourseName())
                            .credits(enrollment.getSection().getCourse().getCredits())
                            .processScore(g.getProcessScore())
                            .examScore(g.getExamScore())
                            .finalScore10(g.getFinalScore10())
                            .finalScore4(g.getFinalScore4())
                            .result(g.getResult())
                            .build());
                }
            }
        }

        return GradeResponse.builder()
                .semester(semester)
                .academicYear(academicYear)
                .grades(new ArrayList<>(itemByCode.values()))
                .build();
    }

    public SemesterSummaryResponse getSemesterSummary(String studentCode, String academicYear, String semester) {
        studentRepository.findByStudentCode(studentCode)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy sinh viên"));

        Optional<SemesterSummary> opt = semesterSummaryRepository
                .findByStudentAndSemester(studentCode, academicYear, semester);

        if (opt.isEmpty()) {
            return SemesterSummaryResponse.builder()
                    .semester(semester).academicYear(academicYear).build();
        }

        SemesterSummary ss = opt.get();
        return SemesterSummaryResponse.builder()
                .semester(ss.getSemester()).academicYear(ss.getAcademicYear())
                .gpa10(ss.getGpa10()).gpa4(ss.getGpa4())
                .cumulativeGpa10(ss.getCumulativeGpa10()).cumulativeGpa4(ss.getCumulativeGpa4())
                .semesterCredits(ss.getSemesterCredits()).cumulativeCredits(ss.getCumulativeCredits())
                .build();
    }
}
