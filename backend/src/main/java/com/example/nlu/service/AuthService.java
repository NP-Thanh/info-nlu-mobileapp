package com.example.nlu.service;

import com.example.nlu.dto.request.LoginRequest;
import com.example.nlu.dto.response.LoginResponse;
import com.example.nlu.entity.Student;
import com.example.nlu.entity.User;
import com.example.nlu.jwt.JwtUtil;
import com.example.nlu.repo.StudentRepository;
import com.example.nlu.repo.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public LoginResponse login(LoginRequest request) {
        log.info("Login attempt for studentId: {}", request.getStudentId());

        User user = userRepository.findByUsername(request.getStudentId())
                .orElseThrow(() -> {
                    log.warn("User not found: {}", request.getStudentId());
                    return new RuntimeException("Sai mã số sinh viên hoặc mật khẩu");
                });

        log.info("User found: {}, stored hash: {}", user.getUsername(), user.getPassword());

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            log.warn("Password mismatch for user: {}", user.getUsername());
            throw new RuntimeException("Sai mã số sinh viên hoặc mật khẩu");
        }

        Student student = studentRepository.findByUser_Id(user.getId())
                .orElseThrow(() -> {
                    log.warn("Student not found for userId: {}", user.getId());
                    return new RuntimeException("Không tìm thấy thông tin sinh viên");
                });

        String token = jwtUtil.generateToken(user.getUsername(), user.getRole().name());
        log.info("Login success for: {}", user.getUsername());

        return new LoginResponse(token, student.getStudentCode(), student.getFullName(), user.getRole().name());
    }
}
