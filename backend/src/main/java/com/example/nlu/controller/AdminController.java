package com.example.nlu.controller;

import com.example.nlu.dto.request.CreateStudentRequest;
import com.example.nlu.dto.request.StudentIdsRequest;
import com.example.nlu.dto.request.UpdateScheduleRequest;
import com.example.nlu.dto.request.UpdateStudentRequest;
import com.example.nlu.dto.response.AdminStudentResponse;
import com.example.nlu.dto.response.GradeResponse;
import com.example.nlu.entity.Course;
import com.example.nlu.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class AdminController {

    private final AdminStudentService adminStudentService;
    private final AdminAcademicService adminAcademicService;
    private final AdminProgramService adminProgramService;
    private final AdminScheduleService adminScheduleService;
    private final GradeService gradeService;

    @GetMapping("/students")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudents(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String className,
            @RequestParam(required = false) String faculty,
            @RequestParam(required = false) Integer startYear,
            @RequestParam(required = false) String status
    ) {
        try {
            List<AdminStudentResponse> result = adminStudentService.getStudents(keyword, className, faculty, startYear, status);
            return ResponseEntity.ok(Map.of("total", result.size(), "data", result));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @GetMapping("/students/filter-suggestions")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentFilterSuggestions(
            @RequestParam String type,
            @RequestParam(required = false) String keyword
    ) {
        try {
            return ResponseEntity.ok(Map.of("data", adminStudentService.getFilterSuggestions(type, keyword)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/students/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentDetail(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(Map.of("data", adminStudentService.getStudentDetail(id)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/students")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createStudent(@RequestBody CreateStudentRequest request) {
        try {
            AdminStudentResponse result = adminStudentService.createStudent(request);
            return ResponseEntity.ok(Map.of("message", "Thêm sinh viên thành công", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PutMapping("/students/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateStudent(@PathVariable Long id,
                                           @RequestBody UpdateStudentRequest request) {
        try {
            AdminStudentResponse result = adminStudentService.updateStudent(id, request);
            return ResponseEntity.ok(Map.of("message", "Cập nhật sinh viên thành công", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/students/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteStudent(@PathVariable Long id) {
        try {
            adminStudentService.deleteStudent(id);
            return ResponseEntity.ok(Map.of("message", "Đã vô hiệu hóa sinh viên"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/students")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteStudentsBulk(@RequestBody StudentIdsRequest request) {
        try {
            int count = adminStudentService.deleteStudentsBulk(request.getIds());
            return ResponseEntity.ok(Map.of("message", "Đã vô hiệu hóa " + count + " sinh viên"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @GetMapping("/programs/faculties")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getProgramFaculties() {
        return ResponseEntity.ok(Map.of("data", adminProgramService.getFaculties()));
    }

    @GetMapping("/programs/majors")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getProgramMajors(@RequestParam String faculty) {
        try {
            return ResponseEntity.ok(Map.of("data", adminProgramService.getMajors(faculty)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/programs/specializations")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getProgramSpecializations(
            @RequestParam String faculty,
            @RequestParam String major
    ) {
        try {
            return ResponseEntity.ok(Map.of("data", adminProgramService.getSpecializations(faculty, major)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/programs/resolve")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> resolveProgram(
            @RequestParam String faculty,
            @RequestParam String major,
            @RequestParam String specialization
    ) {
        try {
            return ResponseEntity.ok(Map.of("data", adminProgramService.resolveProgramId(faculty, major, specialization)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/students/{id}/schedule/latest")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentLatestSchedule(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(Map.of("data", adminScheduleService.getLatestSchedule(id)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PutMapping("/schedules/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateSchedule(@PathVariable Long id, @RequestBody UpdateScheduleRequest request) {
        try {
            return ResponseEntity.ok(Map.of(
                    "message", "Cập nhật lịch học thành công",
                    "data", adminScheduleService.updateSchedule(id, request)
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/schedules/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteSchedule(@PathVariable Long id) {
        try {
            adminScheduleService.deleteSchedule(id);
            return ResponseEntity.ok(Map.of("message", "Xóa lịch học thành công"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @GetMapping("/students/{id}/grades/semesters")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentGradeSemesters(@PathVariable Long id) {
        try {
            var detail = adminStudentService.getStudentDetail(id);
            return ResponseEntity.ok(Map.of(
                    "data", gradeService.getAvailableSemesters(detail.getStudentCode())
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/students/{id}/grades")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentGrades(
            @PathVariable Long id,
            @RequestParam("academic_year") String academicYear,
            @RequestParam String semester
    ) {
        try {
            var detail = adminStudentService.getStudentDetail(id);
            String mssv = detail.getStudentCode();
            GradeResponse grades = gradeService.getGrades(mssv, academicYear, semester);
            var summary = gradeService.getSemesterSummary(mssv, academicYear, semester);
            return ResponseEntity.ok(Map.of("data", Map.of(
                    "semester", grades.getSemester(),
                    "academicYear", grades.getAcademicYear(),
                    "grades", grades.getGrades(),
                    "semesterSummary", summary
            )));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/courses")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getCourses() {
        List<Course> courses = adminAcademicService.getCourses();
        return ResponseEntity.ok(Map.of("total", courses.size(), "data", courses));
    }

    @PostMapping("/courses")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createCourse(@RequestBody Map<String, Object> request) {
        try {
            Course course = adminAcademicService.createCourse(
                    (String) request.get("course_code"),
                    (String) request.get("name"),
                    request.get("credits") == null ? null : ((Number) request.get("credits")).intValue()
            );
            return ResponseEntity.ok(Map.of("message", "Thêm môn học thành công", "data", course));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PutMapping("/courses/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateCourse(@PathVariable Long id, @RequestBody Map<String, Object> request) {
        try {
            Course course = adminAcademicService.updateCourse(
                    id,
                    (String) request.get("course_code"),
                    (String) request.get("name"),
                    request.get("credits") == null ? null : ((Number) request.get("credits")).intValue()
            );
            return ResponseEntity.ok(Map.of("message", "Cập nhật môn học thành công", "data", course));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/courses/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteCourse(@PathVariable Long id) {
        try {
            adminAcademicService.deleteCourse(id);
            return ResponseEntity.ok(Map.of("message", "Xóa môn học thành công"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/courses/import")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> importCourses(@RequestParam("file") MultipartFile file) {
        try {
            Map<String, Object> result = adminAcademicService.importCourses(file);
            return ResponseEntity.ok(Map.of("message", "Import môn học hoàn tất", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/grades/manual")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> upsertManualGrade(@RequestBody Map<String, Object> request) {
        try {
            Map<String, Object> result = adminAcademicService.upsertManualGradeWithTerm(
                    (String) request.get("mssv"),
                    (String) request.get("academic_year"),
                    String.valueOf(request.get("semester")),
                    (String) request.get("course_code"),
                    request.get("process_score") == null ? null : ((Number) request.get("process_score")).floatValue(),
                    request.get("exam_score") == null ? null : ((Number) request.get("exam_score")).floatValue()
            );
            return ResponseEntity.ok(Map.of("message", "Lưu điểm thành công", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @GetMapping("/grades/students/suggestions")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentSuggestions(@RequestParam(required = false) String keyword) {
        return ResponseEntity.ok(Map.of(
                "data", adminAcademicService.searchStudentSuggestions(keyword)
        ));
    }

    @GetMapping("/grades/students/{mssv}/terms")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentTerms(@PathVariable String mssv) {
        try {
            return ResponseEntity.ok(Map.of(
                    "data", adminAcademicService.getStudentTerms(mssv)
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/grades/students/{mssv}/courses")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentCourses(
            @PathVariable String mssv,
            @RequestParam("academic_year") String academicYear,
            @RequestParam("semester") String semester,
            @RequestParam(required = false) String keyword
    ) {
        try {
            return ResponseEntity.ok(Map.of(
                    "data", adminAcademicService.getStudentCoursesByTerm(mssv, academicYear, semester, keyword)
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PostMapping("/grades/import")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> importGrades(@RequestParam("course_code") String courseCode,
                                          @RequestParam("file") MultipartFile file) {
        try {
            Map<String, Object> result = adminAcademicService.importGrades(courseCode, file);
            return ResponseEntity.ok(Map.of("message", "Import điểm hoàn tất", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }
}
