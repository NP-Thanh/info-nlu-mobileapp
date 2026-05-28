package com.example.nlu.service;

import com.example.nlu.dto.request.ChangePasswordRequest;
import com.example.nlu.dto.request.LoginRequest;
import com.example.nlu.dto.response.LoginResponse;
import com.example.nlu.entity.Role;
import com.example.nlu.entity.Student;
import com.example.nlu.entity.StudentStatus;
import com.example.nlu.entity.User;
import com.example.nlu.jwt.JwtUtil;
import com.example.nlu.repo.StudentRepository;
import com.example.nlu.repo.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public LoginResponse login(LoginRequest request) {
        String username = request.getStudentId();
        log.info("Login attempt for username: {}", username);

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> {
                    log.warn("User not found: {}", username);
                    return new RuntimeException("Sai tài khoản hoặc mật khẩu");
                });

        log.info("User found: {}, stored hash: {}", user.getUsername(), user.getPassword());

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            log.warn("Password mismatch for user: {}", user.getUsername());
            throw new RuntimeException("Sai tài khoản hoặc mật khẩu");
        }

        String token = jwtUtil.generateToken(user.getUsername(), user.getRole().name());
        log.info("Login success for: {}", user.getUsername());

        if (user.getRole() == null) {
            throw new RuntimeException("Tài khoản chưa được phân quyền");
        }

        if (user.getRole() == Role.ADMIN) {
            return new LoginResponse(token, user.getUsername(), user.getUsername(), user.getRole().name());
        }

        Student student = studentRepository.findByUser_Id(user.getId())
                .orElseThrow(() -> {
                    log.warn("Student not found for userId: {}", user.getId());
                    return new RuntimeException("Không tìm thấy thông tin sinh viên");
                });

        if (!student.getStatus().allowsLogin()) {
            throw new RuntimeException("Tài khoản đang bị vô hiệu hóa");
        }

        return new LoginResponse(token, student.getStudentCode(), student.getFullName(), user.getRole().name());
    }

    @Transactional
    public void changePassword(String username, ChangePasswordRequest request) {
        if (request.getNewPassword() == null || request.getNewPassword().length() < 6) {
            throw new RuntimeException("Mật khẩu mới phải có ít nhất 6 ký tự");
        }

        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new RuntimeException("Mật khẩu xác nhận không khớp");
        }

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy tài khoản"));

        if (!passwordEncoder.matches(request.getOldPassword(), user.getPassword())) {
            throw new RuntimeException("Mật khẩu hiện tại không đúng");
        }

        if (passwordEncoder.matches(request.getNewPassword(), user.getPassword())) {
            throw new RuntimeException("Mật khẩu mới không được trùng với mật khẩu hiện tại");
        }

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        user.setUpdatedAt(LocalDateTime.now());
        userRepository.save(user);
        log.info("Password changed successfully for user: {}", username);
    }
}
