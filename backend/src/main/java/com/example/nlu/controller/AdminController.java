package com.example.nlu.controller;

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

    @GetMapping("/students")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudents(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String className,
            @RequestParam(required = false) String faculty,
            @RequestParam(required = false) Integer startYear
    ) {
        try {
            List<AdminStudentResponse> result = adminStudentService.getStudents(
                    keyword, className, faculty, startYear
            );
            return ResponseEntity.ok(Map.of(
                    "total", result.size(),
                    "data", result
            ));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }
}
