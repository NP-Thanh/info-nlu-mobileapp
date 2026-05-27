package com.example.nlu.controller;

import com.example.nlu.dto.request.CreateStudentRequest;
import com.example.nlu.dto.request.UpdateStudentRequest;
import com.example.nlu.dto.response.AdminStudentResponse;
import com.example.nlu.entity.Course;
import com.example.nlu.service.AdminAcademicService;
import com.example.nlu.service.AdminStudentService;
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

    // GET /api/admin/students
    @GetMapping("/students")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudents(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String className,
            @RequestParam(required = false) String faculty,
            @RequestParam(required = false) Integer startYear
    ) {
        try {
            List<AdminStudentResponse> result = adminStudentService.getStudents(keyword, className, faculty, startYear);
            return ResponseEntity.ok(Map.of("total", result.size(), "data", result));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    // POST /api/admin/students
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

    // PUT /api/admin/students/{id}
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

    // DELETE /api/admin/students/{id}
    @DeleteMapping("/students/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteStudent(@PathVariable Long id) {
        try {
            adminStudentService.deleteStudent(id);
            return ResponseEntity.ok(Map.of("message", "Xóa sinh viên thành công"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
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
            Map<String, Object> result = adminAcademicService.upsertManualGrade(
                    (String) request.get("course_code"),
                    (String) request.get("mssv"),
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
