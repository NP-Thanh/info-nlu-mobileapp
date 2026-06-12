package com.example.nlu.service;

import com.example.nlu.entity.Role;
import com.example.nlu.entity.User;
import com.example.nlu.repo.UserDeviceRepository;
import com.example.nlu.repo.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AdminUserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JavaMailSender mailSender;
    private final TokenBlacklistService tokenBlacklistService;
    private final UserDeviceRepository userDeviceRepository;

    @Value("${jwt.expiration}")
    private long jwtExpiration;

    private static final String CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    public List<Map<String, Object>> getAdminUsers(String keyword) {
        String kw = (keyword == null || keyword.isBlank()) ? null : keyword.trim();
        return userRepository.findByRoleAndKeyword(Role.ADMIN, kw)
                .stream()
                .map(u -> Map.<String, Object>of(
                        "id", u.getId(),
                        "username", u.getUsername(),
                        "email", u.getEmail() != null ? u.getEmail() : "",
                        "createdAt", u.getCreatedAt() != null ? u.getCreatedAt().toString() : ""
                ))
                .collect(Collectors.toList());
    }

    @Transactional
    public Map<String, Object> createAdminUser(String username, String email) {
        if (username == null || username.isBlank())
            throw new IllegalArgumentException("Username không được để trống");
        if (email == null || email.isBlank())
            throw new IllegalArgumentException("Email không được để trống");
        if (!email.matches("^[\\w.+\\-]+@[\\w\\-]+\\.[a-zA-Z]{2,}$"))
            throw new IllegalArgumentException("Email không hợp lệ");
        if (userRepository.existsByUsername(username.trim()))
            throw new IllegalArgumentException("Username đã tồn tại");
        if (userRepository.existsByEmail(email.trim()))
            throw new IllegalArgumentException("Email đã được sử dụng");

        String rawPassword = generatePassword();

        User user = new User();
        user.setUsername(username.trim());
        user.setEmail(email.trim());
        user.setPassword(passwordEncoder.encode(rawPassword));
        user.setRole(Role.ADMIN);
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());
        userRepository.save(user);

        sendWelcomeEmail(email.trim(), username.trim(), rawPassword);

        return Map.of(
                "id", user.getId(),
                "username", user.getUsername(),
                "email", user.getEmail(),
                "createdAt", user.getCreatedAt().toString()
        );
    }

    @Transactional
    public void deleteAdminUsers(List<Long> ids) {
        if (ids == null || ids.isEmpty())
            throw new IllegalArgumentException("Danh sách id không được để trống");
        List<User> users = userRepository.findAllById(ids);
        for (User u : users) {
            if (u.getRole() != Role.ADMIN)
                throw new IllegalArgumentException("Chỉ được xóa tài khoản admin");
            if ("admin".equalsIgnoreCase(u.getUsername()))
                throw new IllegalArgumentException("Không thể xóa tài khoản super admin (admin)");
        }
        for (User u : users) {
            // Revoke tất cả JWT token đang active
            tokenBlacklistService.revokeAllTokensForUser(
                    u.getUsername(), Duration.ofMillis(jwtExpiration));
            // Xóa device tokens (FCM) để không nhận push notification nữa
            userDeviceRepository.deleteByUser_Id(u.getId());
            // Soft delete user
            u.setIsDeleted(true);
            u.setUpdatedAt(LocalDateTime.now());
            userRepository.save(u);
        }
    }

    private String generatePassword() {
        SecureRandom random = new SecureRandom();
        StringBuilder sb = new StringBuilder(12);
        for (int i = 0; i < 12; i++) {
            sb.append(CHARS.charAt(random.nextInt(CHARS.length())));
        }
        return sb.toString();
    }

    private void sendWelcomeEmail(String email, String username, String password) {
        try {
            SimpleMailMessage msg = new SimpleMailMessage();
            msg.setTo(email);
            msg.setSubject("[Thông tin NLUers] Tài khoản Admin của bạn");
            msg.setText(
                "Xin chào " + username + ",\n\n" +
                "Tài khoản Admin của bạn đã được tạo trên hệ thống Thông tin NLUers.\n\n" +
                "Tên đăng nhập: " + username + "\n" +
                "Mật khẩu:      " + password + "\n\n" +
                "Vui lòng đăng nhập và đổi mật khẩu ngay sau khi nhận được email này.\n\n" +
                "Trân trọng,\nHệ thống Thông tin NLUers\nTrường Đại học Nông Lâm TP.HCM"
            );
            mailSender.send(msg);
            log.info("Welcome email sent to admin: {}", email);
        } catch (Exception e) {
            log.error("Failed to send welcome email to {}: {}", email, e.getMessage());
            throw new RuntimeException("Tạo tài khoản thành công nhưng không thể gửi email. Vui lòng kiểm tra lại địa chỉ email.");
        }
    }
}
