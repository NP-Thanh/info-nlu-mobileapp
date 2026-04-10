package com.example.nlu.controller;

import com.example.nlu.dto.response.StudentInfoResponse;
import com.example.nlu.service.StudentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/student")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class StudentController {

    private final StudentService studentService;

    @GetMapping("/info")
    public ResponseEntity<?> getStudentInfo(Authentication authentication) {
        try {
            String studentCode = authentication.getName();
            StudentInfoResponse response = studentService.getStudentInfo(studentCode);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(404).body(Map.of("message", e.getMessage()));
        }
    }
}
