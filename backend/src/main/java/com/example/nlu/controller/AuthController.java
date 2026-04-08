package com.example.nlu.controller;

import com.example.nlu.dto.request.ForgotPasswordRequest;
import com.example.nlu.dto.request.LoginRequest;
import com.example.nlu.dto.response.LoginResponse;
import com.example.nlu.service.AuthService;
import com.example.nlu.service.PasswordResetService;
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
    private final PasswordResetService passwordResetService;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            LoginResponse response = authService.login(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(401).body(Map.of("message", e.getMessage()));
        }
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(@RequestBody ForgotPasswordRequest request) {
        try {
            passwordResetService.resetPassword(request.getStudentCode(), request.getDateOfBirth());
            return ResponseEntity.ok(Map.of("message", "Mật khẩu mới đã được gửi đến email của bạn"));
        } catch (RuntimeException e) {
            return ResponseEntity.status(400).body(Map.of("message", e.getMessage()));
        }
    }
}
