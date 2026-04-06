package com.example.nlu.controller;

import com.example.nlu.entity.Student;
import com.example.nlu.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> body) {
        try {
            String studentId = body.get("studentId");
            String password = body.get("password");
            Student student = authService.login(studentId, password);
            return ResponseEntity.ok(Map.of(
                "message", "Đăng nhập thành công"
            ));
        } catch (RuntimeException e) {
            return ResponseEntity.status(401).body(Map.of("message", e.getMessage()));
        }
    }
}
