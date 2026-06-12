package com.example.nlu.service;

import com.example.nlu.entity.Course;
import com.example.nlu.entity.Enrollment;
import com.example.nlu.entity.Grade;
import com.example.nlu.entity.Section;
import com.example.nlu.entity.SemesterSummary;
import com.example.nlu.entity.Student;
import com.example.nlu.repo.CourseRepository;
import com.example.nlu.repo.EnrollmentRepository;
import com.example.nlu.repo.GradeRepository;
import com.example.nlu.repo.SemesterSummaryRepository;
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
    private final SemesterSummaryRepository semesterSummaryRepository;

    public List<Course> getCourses() {
        return courseRepository.findAllByIsDeletedFalse();
    }

    @Transactional
    public Course createCourse(String courseCode, String name, Integer credits) {
        validateCourseInput(courseCode, name, credits);

        // Nếu mã đã tồn tại và chưa bị xóa → báo trùng
        if (courseRepository.existsByCourseCodeIgnoreCaseAndIsDeletedFalse(courseCode.trim())) {
            throw new IllegalArgumentException("Mã môn học đã tồn tại: " + courseCode);
        }
        // Nếu mã đã bị soft-delete trước đó → restore lại thay vì tạo bản ghi mới
        Optional<Course> deleted = courseRepository.findByCourseCodeIgnoreCaseAndIsDeletedTrue(courseCode.trim());
        Course course = deleted.orElseGet(Course::new);
        course.setCourseCode(courseCode.trim());
        course.setCourseName(name.trim());
        course.setCredits(credits);
        course.setIsDeleted(false);
        return courseRepository.save(course);
    }

    @Transactional
    public Course updateCourse(Long id, String courseCode, String name, Integer credits) {
        validateCourseInput(courseCode, name, credits);
        Course course = courseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy môn học"));
        if (Boolean.TRUE.equals(course.getIsDeleted()))
            throw new IllegalArgumentException("Môn học đã bị xóa, không thể cập nhật");

        Optional<Course> existingByCode = courseRepository.findByCourseCodeIgnoreCaseAndIsDeletedFalse(courseCode.trim());
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
        course.setIsDeleted(true);
        courseRepository.save(course);
    }

    public Map<String, Object> previewCourses(MultipartFile file) {
        if (file == null || file.isEmpty())
            throw new IllegalArgumentException("File excel không được để trống");

        List<Map<String, Object>> validRows = new ArrayList<>();
        List<Map<String, Object>> invalidRows = new ArrayList<>();

        try (InputStream is = file.getInputStream(); Workbook workbook = WorkbookFactory.create(is)) {
            Sheet sheet = workbook.getSheetAt(0);
            if (sheet == null) throw new IllegalArgumentException("Không có sheet dữ liệu");
            validateHeader(sheet, new String[]{"course_code", "name", "credits"});

            for (int rowIndex = 1; rowIndex <= sheet.getLastRowNum(); rowIndex++) {
                Row row = sheet.getRow(rowIndex);
                if (row == null) continue;
                String courseCode = getStringCell(row.getCell(0));
                String name = getStringCell(row.getCell(1));
                Integer credits = null;
                try { credits = getIntCell(row.getCell(2)); } catch (Exception ignored) {}

                Map<String, Object> rowData = new LinkedHashMap<>();
                rowData.put("row", rowIndex + 1);
                rowData.put("courseCode", courseCode);
                rowData.put("courseName", name);
                rowData.put("credits", credits);

                try {
                    validateCourseInput(courseCode, name, credits);
                    if (courseRepository.existsByCourseCodeIgnoreCaseAndIsDeletedFalse(courseCode != null ? courseCode.trim() : ""))
                        throw new IllegalArgumentException("Mã môn học đã tồn tại: " + courseCode);
                    rowData.put("valid", true); rowData.put("error", null);
                    validRows.add(rowData);
                } catch (Exception e) {
                    rowData.put("valid", false); rowData.put("error", e.getMessage());
                    invalidRows.add(rowData);
                }
            }
        } catch (IOException e) {
            throw new IllegalArgumentException("Không đọc được file excel");
        } catch (Exception e) {
            throw new IllegalArgumentException("File excel không hợp lệ: " + e.getMessage());
        }

        List<Map<String, Object>> allRows = new ArrayList<>();
        allRows.addAll(validRows);
        allRows.addAll(invalidRows);
        allRows.sort(Comparator.comparingInt(r -> (int) r.get("row")));
        return Map.of("validCount", validRows.size(), "invalidCount", invalidRows.size(), "rows", allRows);
    }

    public Map<String, Object> previewGrades(String courseCode, MultipartFile file) {
        if (file == null || file.isEmpty())
            throw new IllegalArgumentException("File excel không được để trống");
        if (isBlank(courseCode))
            throw new IllegalArgumentException("course_code không được để trống");
        Course course = getCourseByCode(courseCode);

        List<Map<String, Object>> validRows = new ArrayList<>();
        List<Map<String, Object>> invalidRows = new ArrayList<>();

        try (InputStream is = file.getInputStream(); Workbook workbook = WorkbookFactory.create(is)) {
            Sheet sheet = workbook.getSheetAt(0);
            if (sheet == null) throw new IllegalArgumentException("Không có sheet dữ liệu");
            validateHeader(sheet, new String[]{"mssv", "academic_year", "semester", "process_score", "exam_score"});

            for (int rowIndex = 1; rowIndex <= sheet.getLastRowNum(); rowIndex++) {
                Row row = sheet.getRow(rowIndex);
                if (row == null) continue;

                String studentCode = getStringCell(row.getCell(0));
                String academicYear = getStringCell(row.getCell(1));
                String semester = getStringCell(row.getCell(2));
                Float processScore = null;
                Float examScore = null;
                try { processScore = getFloatCell(row.getCell(3)); } catch (Exception ignored) {}
                try { examScore = getFloatCell(row.getCell(4)); } catch (Exception ignored) {}

                Map<String, Object> rowData = new LinkedHashMap<>();
                rowData.put("row", rowIndex + 1);
                rowData.put("studentCode", studentCode);
                rowData.put("academicYear", academicYear);
                rowData.put("semester", semester);
                rowData.put("processScore", processScore);
                rowData.put("examScore", examScore);

                try {
                    if (isBlank(studentCode)) throw new IllegalArgumentException("MSSV trống");
                    validateTerm(academicYear, semester);
                    validateScore(processScore, "Điểm quá trình");
                    validateScore(examScore, "Điểm thi");

                    Student student = getStudentByCode(studentCode);

                    // Kiểm tra sinh viên có enrollment LT cho môn này trong học kỳ không
                    enrollmentRepository
                            .findTopByStudent_IdAndCourse_IdAndAcademicYearAndSemesterAndIsLabFalseOrderByIdDesc(
                                    student.getId(), course.getId(), academicYear.trim(), semester.trim())
                            .orElseThrow(() -> new IllegalArgumentException(
                                    "Sinh viên " + studentCode + " không có đăng ký lý thuyết môn " + courseCode
                                    + " trong HK " + semester + " - " + academicYear));

                    rowData.put("valid", true); rowData.put("error", null);
                    validRows.add(rowData);
                } catch (Exception e) {
                    rowData.put("valid", false); rowData.put("error", e.getMessage());
                    invalidRows.add(rowData);
                }
            }
        } catch (IOException e) {
            throw new IllegalArgumentException("Không đọc được file excel");
        } catch (Exception e) {
            throw new IllegalArgumentException("File excel không hợp lệ: " + e.getMessage());
        }

        List<Map<String, Object>> allRows = new ArrayList<>();
        allRows.addAll(validRows);
        allRows.addAll(invalidRows);
        allRows.sort(Comparator.comparingInt(r -> (int) r.get("row")));
        return Map.of("validCount", validRows.size(), "invalidCount", invalidRows.size(), "rows", allRows);
    }

    @Transactional
    public Map<String, Object> importCourses(MultipartFile file) {
        if (file == null || file.isEmpty())
            throw new IllegalArgumentException("File excel không được để trống");

        int successCount = 0;
        List<String> errors = new ArrayList<>();

        try (InputStream is = file.getInputStream(); Workbook workbook = WorkbookFactory.create(is)) {
            Sheet sheet = workbook.getSheetAt(0);
            if (sheet == null) throw new IllegalArgumentException("Không có sheet dữ liệu");
            validateHeader(sheet, new String[]{"course_code", "name", "credits"});

            for (int rowIndex = 1; rowIndex <= sheet.getLastRowNum(); rowIndex++) {
                Row row = sheet.getRow(rowIndex);
                if (row == null) continue;
                try {
                    String courseCode = getStringCell(row.getCell(0));
                    String name = getStringCell(row.getCell(1));
                    Integer credits = getIntCell(row.getCell(2));
                    validateCourseInput(courseCode, name, credits);
                    if (courseRepository.existsByCourseCodeIgnoreCaseAndIsDeletedFalse(courseCode.trim()))
                        throw new IllegalArgumentException("Mã môn học đã tồn tại: " + courseCode.trim());
                    // Nếu mã đã bị soft-delete → restore, không tạo bản ghi mới
                    Course course = courseRepository.findByCourseCodeIgnoreCaseAndIsDeletedTrue(courseCode.trim())
                            .orElseGet(Course::new);
                    course.setCourseCode(courseCode.trim());
                    course.setCourseName(name.trim());
                    course.setCredits(credits);
                    course.setIsDeleted(false);
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

        return Map.of("successCount", successCount, "errorCount", errors.size(), "errors", errors);
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
            String studentCode, String academicYear, String semester,
            String courseCode, Float processScore, Float examScore) {
        Student student = getStudentByCode(studentCode);
        Course course = getCourseByCode(courseCode);
        validateTerm(academicYear, semester);
        Grade grade = upsertGrade(student, course, academicYear, semester, processScore, examScore);
        recomputeSemesterSummary(student, academicYear, semester);
        return toGradeResponse(grade, studentCode, courseCode, academicYear, semester);
    }

    @Transactional
    public Map<String, Object> importGrades(String courseCode, MultipartFile file) {
        if (file == null || file.isEmpty())
            throw new IllegalArgumentException("File excel không được để trống");
        Course course = getCourseByCode(courseCode);
        int successCount = 0;
        List<String> errors = new ArrayList<>();

        try (InputStream is = file.getInputStream(); Workbook workbook = WorkbookFactory.create(is)) {
            Sheet sheet = workbook.getSheetAt(0);
            if (sheet == null) throw new IllegalArgumentException("Không có sheet dữ liệu");
            validateHeader(sheet, new String[]{"mssv", "academic_year", "semester", "process_score", "exam_score"});

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
                    recomputeSemesterSummary(student, academicYear, semester);
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

        return Map.of("courseCode", courseCode, "successCount", successCount,
                "errorCount", errors.size(), "errors", errors);
    }

    public List<Map<String, String>> searchStudentSuggestions(String keyword) {
        String kw = isBlank(keyword) ? "" : keyword.trim();
        return studentRepository.searchStudents(kw, null, null)
                .stream().limit(20)
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
                    String code = Optional.ofNullable(enrollment.getSection().getCourse().getCourseCode()).orElse("");
                    String name = Optional.ofNullable(enrollment.getSection().getCourse().getCourseName()).orElse("");
                    Map<String, String> item = new LinkedHashMap<>();
                    item.put("courseCode", code);
                    item.put("courseName", name);
                    item.put("display", code + " - " + name);
                    return item;
                })
                .distinct()
                .toList();
    }

    private Grade upsertGrade(Student student, Course course, String academicYear, String semester,
                               Float processScore, Float examScore) {
        validateScore(processScore, "Điểm quá trình");
        validateScore(examScore, "Điểm thi");

        // Tìm enrollment LT (is_lab=false) của sinh viên trong môn + học kỳ
        Enrollment enrollment;
        if (!isBlank(academicYear) && !isBlank(semester)) {
            enrollment = enrollmentRepository
                    .findTopByStudent_IdAndCourse_IdAndAcademicYearAndSemesterAndIsLabFalseOrderByIdDesc(
                            student.getId(), course.getId(), academicYear.trim(), semester.trim())
                    .orElseThrow(() -> new IllegalArgumentException(
                            "Sinh viên " + student.getStudentCode()
                            + " không có đăng ký lý thuyết môn " + course.getCourseCode()
                            + " trong HK " + semester + " - " + academicYear));
        } else {
            enrollment = enrollmentRepository
                    .findTopByStudent_IdAndCourse_IdAndIsLabFalseOrderByIdDesc(
                            student.getId(), course.getId())
                    .orElseThrow(() -> new IllegalArgumentException(
                            "Sinh viên " + student.getStudentCode()
                            + " chưa đăng ký môn " + course.getCourseCode()));
        }

        Grade grade = gradeRepository.findByEnrollment_Id(enrollment.getId()).orElseGet(Grade::new);
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

    private void recomputeSemesterSummary(Student student, String academicYear, String semester) {
        List<Grade> grades = gradeRepository.findByStudentAndSemester(
                student.getStudentCode(), academicYear, semester);

        Map<String, Grade> gradeByCourseCode = new LinkedHashMap<>();
        for (Grade grade : grades) {
            Section sec = grade.getEnrollment() != null ? grade.getEnrollment().getSection() : null;
            if (sec == null || sec.getCourse() == null) continue;
            String courseCode = sec.getCourse().getCourseCode();
            if (isBlank(courseCode) || grade.getFinalScore10() == null || grade.getFinalScore4() == null) continue;
            Grade existing = gradeByCourseCode.get(courseCode);
            boolean isCurrentTheory = sec.getIsLab() == null || !sec.getIsLab();
            if (existing == null) {
                gradeByCourseCode.put(courseCode, grade);
            } else {
                Section existingSec = existing.getEnrollment().getSection();
                boolean existingTheory = existingSec.getIsLab() == null || !existingSec.getIsLab();
                if (!existingTheory && isCurrentTheory) {
                    gradeByCourseCode.put(courseCode, grade);
                }
            }
        }

        double weighted10 = 0, weighted4 = 0;
        int gradedCredits = 0, passedCredits = 0;

        for (Grade grade : gradeByCourseCode.values()) {
            Integer credits = grade.getEnrollment().getSection().getCourse().getCredits();
            if (credits == null || credits <= 0) continue;
            weighted10 += grade.getFinalScore10() * credits;
            weighted4 += grade.getFinalScore4() * credits;
            gradedCredits += credits;
            if ("Passed".equalsIgnoreCase(grade.getResult())) passedCredits += credits;
        }

        float gpa10 = gradedCredits == 0 ? 0f : round2(weighted10 / gradedCredits);
        float gpa4 = gradedCredits == 0 ? 0f : round2(weighted4 / gradedCredits);

        SemesterSummary summary = semesterSummaryRepository
                .findByStudentAndSemester(student.getStudentCode(), academicYear, semester)
                .orElseGet(SemesterSummary::new);
        summary.setStudent(student);
        summary.setAcademicYear(academicYear);
        summary.setSemester(semester);
        summary.setGpa10(gpa10);
        summary.setGpa4(gpa4);
        summary.setSemesterCredits(passedCredits);

        SemesterSummary previous = findNearestPreviousSummary(student.getId(), academicYear, semester);
        if (previous == null) {
            summary.setCumulativeGpa10(gpa10);
            summary.setCumulativeGpa4(gpa4);
            summary.setCumulativeCredits(passedCredits);
        } else {
            int previousCredits = Optional.ofNullable(previous.getCumulativeCredits()).orElse(0);
            int totalCredits = previousCredits + passedCredits;
            if (totalCredits == 0) {
                summary.setCumulativeGpa10(0f);
                summary.setCumulativeGpa4(0f);
            } else {
                double cumulative10 = (Optional.ofNullable(previous.getCumulativeGpa10()).orElse(0f) * previousCredits
                        + gpa10 * passedCredits) / totalCredits;
                double cumulative4 = (Optional.ofNullable(previous.getCumulativeGpa4()).orElse(0f) * previousCredits
                        + gpa4 * passedCredits) / totalCredits;
                summary.setCumulativeGpa10(round2(cumulative10));
                summary.setCumulativeGpa4(round2(cumulative4));
            }
            summary.setCumulativeCredits(totalCredits);
        }
        semesterSummaryRepository.save(summary);
    }

    private SemesterSummary findNearestPreviousSummary(Long studentId, String academicYear, String semester) {
        List<SemesterSummary> all = semesterSummaryRepository.findAllByStudentId(studentId);
        int currentOrder = termOrder(academicYear, semester);
        SemesterSummary nearest = null;
        int nearestOrder = Integer.MIN_VALUE;
        for (SemesterSummary item : all) {
            int itemOrder = termOrder(item.getAcademicYear(), item.getSemester());
            if (itemOrder < currentOrder && itemOrder > nearestOrder) {
                nearest = item;
                nearestOrder = itemOrder;
            }
        }
        return nearest;
    }

    private int termOrder(String academicYear, String semester) {
        if (isBlank(academicYear) || isBlank(semester)) return Integer.MIN_VALUE;
        int startYear;
        try { startYear = Integer.parseInt(academicYear.trim().split("-")[0]); }
        catch (Exception ex) { startYear = 0; }
        int sem;
        try { sem = Integer.parseInt(semester.trim()); }
        catch (Exception ex) { sem = 0; }
        return startYear * 10 + sem;
    }

    private Map<String, Object> toGradeResponse(Grade grade, String studentCode, String courseCode,
                                                  String academicYear, String semester) {
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
        if (isBlank(courseCode)) throw new IllegalArgumentException("course_code không được để trống");
        return courseRepository.findByCourseCodeIgnoreCaseAndIsDeletedFalse(courseCode.trim())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy môn học: " + courseCode));
    }

    private Student getStudentByCode(String studentCode) {
        if (isBlank(studentCode)) throw new IllegalArgumentException("mssv không được để trống");
        return studentRepository.findByStudentCode(studentCode.trim())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sinh viên: " + studentCode));
    }

    private void validateCourseInput(String courseCode, String name, Integer credits) {
        if (isBlank(courseCode)) throw new IllegalArgumentException("course_code không được để trống");
        if (isBlank(name)) throw new IllegalArgumentException("name không được để trống");
        if (credits == null || credits < 2) throw new IllegalArgumentException("credits phải >= 2");
    }

    private void validateScore(Float score, String label) {
        if (score == null) throw new IllegalArgumentException(label + " không được để trống");
        if (score < 0 || score > 10) throw new IllegalArgumentException(label + " phải trong khoảng 0-10");
    }

    private void validateTerm(String academicYear, String semester) {
        if (isBlank(academicYear)) throw new IllegalArgumentException("academic_year không được để trống");
        if (isBlank(semester)) throw new IllegalArgumentException("semester không được để trống");
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

    private float round1(float value) { return Math.round(value * 10f) / 10f; }
    private float round2(double value) { return (float) (Math.round(value * 100.0) / 100.0); }

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
        if (cell.getCellType() == CellType.NUMERIC) return (int) cell.getNumericCellValue();
        if (cell.getCellType() == CellType.STRING) return Integer.parseInt(cell.getStringCellValue().trim());
        return null;
    }

    private Float getFloatCell(Cell cell) {
        if (cell == null) return null;
        if (cell.getCellType() == CellType.NUMERIC) return (float) cell.getNumericCellValue();
        if (cell.getCellType() == CellType.STRING) return Float.parseFloat(cell.getStringCellValue().trim());
        return null;
    }

    private boolean isBlank(String s) { return s == null || s.isBlank(); }

    private void validateHeader(Sheet sheet, String[] expectedHeaders) {
        Row headerRow = sheet.getRow(0);
        if (headerRow == null)
            throw new IllegalArgumentException("File thiếu dòng header. Dòng đầu tiên phải là: "
                    + String.join(" | ", expectedHeaders));
        for (int i = 0; i < expectedHeaders.length; i++) {
            Cell cell = headerRow.getCell(i);
            String actual = cell == null ? "" : getStringCell(cell);
            String expected = expectedHeaders[i];
            if (actual == null || !actual.trim().equalsIgnoreCase(expected))
                throw new IllegalArgumentException("Header không đúng. Cột " + (i + 1) + " phải là \""
                        + expected + "\" nhưng nhận \"" + (actual == null ? "(trống)" : actual.trim()) + "\"");
        }
    }
}
