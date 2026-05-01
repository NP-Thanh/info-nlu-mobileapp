package com.example.nlu.controller;

import com.example.nlu.dto.request.CreateStudentRequest;
import com.example.nlu.dto.request.UpdateStudentRequest;
import com.example.nlu.dto.response.AdminStudentResponse;
import com.example.nlu.service.AdminStudentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class AdminController {

    private final AdminStudentService adminStudentService;

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
}
