package com.example.nlu.service;

import com.example.nlu.entity.Course;
import com.example.nlu.entity.Enrollment;
import com.example.nlu.entity.Grade;
import com.example.nlu.entity.Student;
import com.example.nlu.repo.CourseRepository;
import com.example.nlu.repo.EnrollmentRepository;
import com.example.nlu.repo.GradeRepository;
import com.example.nlu.repo.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.util.*;

@Service
@RequiredArgsConstructor
public class AdminAcademicService {

    private final CourseRepository courseRepository;
    private final StudentRepository studentRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final GradeRepository gradeRepository;

    public List<Course> getCourses() {
        return courseRepository.findAll();
    }

    @Transactional
    public Course createCourse(String courseCode, String name, Integer credits) {
        validateCourseInput(courseCode, name, credits);
        if (courseRepository.existsByCourseCodeIgnoreCase(courseCode)) {
            throw new IllegalArgumentException("Mã môn học đã tồn tại: " + courseCode);
        }

        Course course = new Course();
        course.setCourseCode(courseCode.trim());
        course.setCourseName(name.trim());
        course.setCredits(credits);
        return courseRepository.save(course);
    }

    @Transactional
    public Course updateCourse(Long id, String courseCode, String name, Integer credits) {
        validateCourseInput(courseCode, name, credits);
        Course course = courseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy môn học"));

        Optional<Course> existingByCode = courseRepository.findByCourseCodeIgnoreCase(courseCode.trim());
        if (existingByCode.isPresent() && !existingByCode.get().getId().equals(id)) {
            throw new IllegalArgumentException("Mã môn học đã tồn tại: " + courseCode);
        }

        course.setCourseCode(courseCode.trim());
        course.setCourseName(name.trim());
        course.setCredits(credits);
        return courseRepository.save(course);
    }

    @Transactional
    public void deleteCourse(Long id) {
        Course course = courseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy môn học"));
        courseRepository.delete(course);
    }

    @Transactional
    public Map<String, Object> importCourses(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File excel không được để trống");
        }

        int successCount = 0;
        List<String> errors = new ArrayList<>();

        try (InputStream is = file.getInputStream(); Workbook workbook = WorkbookFactory.create(is)) {
            Sheet sheet = workbook.getSheetAt(0);
            if (sheet == null) {
                throw new IllegalArgumentException("Không có sheet dữ liệu");
            }

            for (int rowIndex = 1; rowIndex <= sheet.getLastRowNum(); rowIndex++) {
                Row row = sheet.getRow(rowIndex);
                if (row == null) {
                    continue;
                }
                try {
                    String courseCode = getStringCell(row.getCell(0));
                    String name = getStringCell(row.getCell(1));
                    Integer credits = getIntCell(row.getCell(2));

                    validateCourseInput(courseCode, name, credits);

                    Course course = courseRepository.findByCourseCodeIgnoreCase(courseCode.trim())
                            .orElseGet(Course::new);
                    course.setCourseCode(courseCode.trim());
                    course.setCourseName(name.trim());
                    course.setCredits(credits);
                    courseRepository.save(course);
                    successCount++;
                } catch (Exception e) {
                    errors.add("Dòng " + (rowIndex + 1) + ": " + e.getMessage());
                }
            }
        } catch (IOException e) {
            throw new IllegalArgumentException("Không đọc được file excel");
        } catch (Exception e) {
            throw new IllegalArgumentException("File excel không hợp lệ: " + e.getMessage());
        }

        return Map.of(
                "successCount", successCount,
                "errorCount", errors.size(),
                "errors", errors
        );
    }

    @Transactional
    public Map<String, Object> upsertManualGrade(String courseCode, String studentCode, Float processScore, Float examScore) {
        Course course = getCourseByCode(courseCode);
        Student student = getStudentByCode(studentCode);
        Grade grade = upsertGrade(student, course, null, null, processScore, examScore);
        return toGradeResponse(grade, studentCode, courseCode, null, null);
    }

    @Transactional
    public Map<String, Object> upsertManualGradeWithTerm(
            String studentCode,
            String academicYear,
            String semester,
            String courseCode,
            Float processScore,
            Float examScore
    ) {
        Student student = getStudentByCode(studentCode);
        Course course = getCourseByCode(courseCode);
        validateTerm(academicYear, semester);

        Grade grade = upsertGrade(student, course, academicYear, semester, processScore, examScore);
        return toGradeResponse(grade, studentCode, courseCode, academicYear, semester);
    }

    @Transactional
    public Map<String, Object> importGrades(String courseCode, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File excel không được để trống");
        }
        Course course = getCourseByCode(courseCode);
        int successCount = 0;
        List<String> errors = new ArrayList<>();

        try (InputStream is = file.getInputStream(); Workbook workbook = WorkbookFactory.create(is)) {
            Sheet sheet = workbook.getSheetAt(0);
            if (sheet == null) {
                throw new IllegalArgumentException("Không có sheet dữ liệu");
            }

            for (int rowIndex = 1; rowIndex <= sheet.getLastRowNum(); rowIndex++) {
                Row row = sheet.getRow(rowIndex);
                if (row == null) continue;

                try {
                    String studentCode = getStringCell(row.getCell(0));
                    String academicYear = getStringCell(row.getCell(1));
                    String semester = getStringCell(row.getCell(2));
                    Float processScore = getFloatCell(row.getCell(3));
                    Float examScore = getFloatCell(row.getCell(4));

                    Student student = getStudentByCode(studentCode);
                    validateTerm(academicYear, semester);
                    upsertGrade(student, course, academicYear, semester, processScore, examScore);
                    successCount++;
                } catch (Exception e) {
                    errors.add("Dòng " + (rowIndex + 1) + ": " + e.getMessage());
                }
            }
        } catch (IOException e) {
            throw new IllegalArgumentException("Không đọc được file excel");
        } catch (Exception e) {
            throw new IllegalArgumentException("File excel không hợp lệ: " + e.getMessage());
        }

        return Map.of(
                "courseCode", courseCode,
                "successCount", successCount,
                "errorCount", errors.size(),
                "errors", errors
        );
    }

    public List<Map<String, String>> searchStudentSuggestions(String keyword) {
        String kw = isBlank(keyword) ? "" : keyword.trim();
        return studentRepository.searchStudents(kw, null)
                .stream()
                .limit(20)
                .map(s -> Map.of(
                        "studentCode", s.getStudentCode(),
                        "fullName", Optional.ofNullable(s.getFullName()).orElse("")
                ))
                .toList();
    }

    public List<Map<String, String>> getStudentTerms(String studentCode) {
        getStudentByCode(studentCode);
        return enrollmentRepository.findTermsByStudentCode(studentCode.trim())
                .stream()
                .map(row -> Map.of(
                        "semester", String.valueOf(row[0]),
                        "academicYear", String.valueOf(row[1]),
                        "label", "Học kỳ " + row[0] + ", năm học " + row[1]
                ))
                .toList();
    }

    public List<Map<String, String>> getStudentCoursesByTerm(String studentCode, String academicYear, String semester, String keyword) {
        getStudentByCode(studentCode);
        validateTerm(academicYear, semester);
        String kw = isBlank(keyword) ? null : keyword.trim();
        return enrollmentRepository.findCoursesByStudentAndTerm(studentCode.trim(), academicYear.trim(), semester.trim(), kw)
                .stream()
                .map(enrollment -> {
                    String code = Optional.ofNullable(enrollment.getCourse().getCourseCode()).orElse("");
                    String name = Optional.ofNullable(enrollment.getCourse().getCourseName()).orElse("");
                    Map<String, String> item = new LinkedHashMap<>();
                    item.put("courseCode", code);
                    item.put("courseName", name);
                    item.put("display", code + " - " + name);
                    return item;
                })
                .distinct()
                .toList();
    }

    private Grade upsertGrade(
            Student student,
            Course course,
            String academicYear,
            String semester,
            Float processScore,
            Float examScore
    ) {
        validateScore(processScore, "Điểm quá trình");
        validateScore(examScore, "Điểm thi");

        Enrollment enrollment;
        if (!isBlank(academicYear) && !isBlank(semester)) {
            enrollment = enrollmentRepository.findTopByStudent_IdAndCourse_IdAndAcademicYearAndSemesterAndIsLabFalseOrderByIdDesc(
                    student.getId(), course.getId(), academicYear.trim(), semester.trim()
            ).orElseThrow(() -> new IllegalArgumentException(
                    "Không tìm thấy enrollment lý thuyết (is_lab=0) cho môn học trong học kỳ/năm học đã chọn"
            ));
        } else {
            enrollment = enrollmentRepository.findTopByStudent_IdAndCourse_IdAndIsLabFalseOrderByIdDesc(
                            student.getId(), course.getId()
                    )
                    .orElseGet(() -> {
                        Enrollment e = new Enrollment();
                        e.setStudent(student);
                        e.setCourse(course);
                        e.setAttempt(1);
                        e.setIsLab(false);
                        return enrollmentRepository.save(e);
                    });
        }

        Grade grade = gradeRepository.findByEnrollment_Id(enrollment.getId())
                .orElseGet(Grade::new);
        grade.setEnrollment(enrollment);
        grade.setProcessScore(processScore);
        grade.setExamScore(examScore);

        float final10 = round1((processScore + examScore) / 2f);
        float final4 = convertTo4Scale(final10);
        grade.setFinalScore10(final10);
        grade.setFinalScore4(final4);
        grade.setResult(final10 < 4f ? "Failed" : "Passed");
        return gradeRepository.save(grade);
    }

    private Map<String, Object> toGradeResponse(
            Grade grade,
            String studentCode,
            String courseCode,
            String academicYear,
            String semester
    ) {
        return Map.of(
                "studentCode", studentCode,
                "courseCode", courseCode,
                "academicYear", academicYear == null ? "" : academicYear,
                "semester", semester == null ? "" : semester,
                "processScore", grade.getProcessScore(),
                "examScore", grade.getExamScore(),
                "finalScore10", grade.getFinalScore10(),
                "finalScore4", grade.getFinalScore4(),
                "result", grade.getResult()
        );
    }

    private Course getCourseByCode(String courseCode) {
        if (isBlank(courseCode)) {
            throw new IllegalArgumentException("course_code không được để trống");
        }
        return courseRepository.findByCourseCodeIgnoreCase(courseCode.trim())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy môn học: " + courseCode));
    }

    private Student getStudentByCode(String studentCode) {
        if (isBlank(studentCode)) {
            throw new IllegalArgumentException("mssv không được để trống");
        }
        return studentRepository.findByStudentCode(studentCode.trim())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sinh viên: " + studentCode));
    }

    private void validateCourseInput(String courseCode, String name, Integer credits) {
        if (isBlank(courseCode)) {
            throw new IllegalArgumentException("course_code không được để trống");
        }
        if (isBlank(name)) {
            throw new IllegalArgumentException("name không được để trống");
        }
        if (credits == null || credits < 2) {
            throw new IllegalArgumentException("credits phải >= 2");
        }
    }

    private void validateScore(Float score, String label) {
        if (score == null) {
            throw new IllegalArgumentException(label + " không được để trống");
        }
        if (score < 0 || score > 10) {
            throw new IllegalArgumentException(label + " phải trong khoảng 0-10");
        }
    }

    private void validateTerm(String academicYear, String semester) {
        if (isBlank(academicYear)) {
            throw new IllegalArgumentException("academic_year không được để trống");
        }
        if (isBlank(semester)) {
            throw new IllegalArgumentException("semester không được để trống");
        }
    }

    private float convertTo4Scale(float final10) {
        if (final10 >= 8.5f) return 4.0f;
        if (final10 >= 8.0f) return 3.5f;
        if (final10 >= 7.0f) return 3.0f;
        if (final10 >= 6.5f) return 2.5f;
        if (final10 >= 5.5f) return 2.0f;
        if (final10 >= 5.0f) return 1.5f;
        if (final10 >= 4.0f) return 1.0f;
        return 0.0f;
    }

    private float round1(float value) {
        return Math.round(value * 10f) / 10f;
    }

    private String getStringCell(Cell cell) {
        if (cell == null) return null;
        return switch (cell.getCellType()) {
            case STRING -> cell.getStringCellValue();
            case NUMERIC -> String.valueOf((long) cell.getNumericCellValue());
            case BOOLEAN -> String.valueOf(cell.getBooleanCellValue());
            default -> null;
        };
    }

    private Integer getIntCell(Cell cell) {
        if (cell == null) return null;
        if (cell.getCellType() == CellType.NUMERIC) {
            return (int) cell.getNumericCellValue();
        }
        if (cell.getCellType() == CellType.STRING) {
            return Integer.parseInt(cell.getStringCellValue().trim());
        }
        return null;
    }

    private Float getFloatCell(Cell cell) {
        if (cell == null) return null;
        if (cell.getCellType() == CellType.NUMERIC) {
            return (float) cell.getNumericCellValue();
        }
        if (cell.getCellType() == CellType.STRING) {
            return Float.parseFloat(cell.getStringCellValue().trim());
        }
        return null;
    }

    private boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
