package com.example.nlu.service;

import com.example.nlu.entity.Student;
import com.example.nlu.entity.User;
import com.example.nlu.repo.StudentRepository;
import com.example.nlu.repo.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Slf4j
@Service
@RequiredArgsConstructor
public class PasswordResetService {

    private final StudentRepository studentRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JavaMailSender mailSender;

    private static final String CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    private static final int PASSWORD_LENGTH = 10;

    @Transactional
    public void resetPassword(String studentCode, String dateOfBirthStr) {
        // Parse ngày sinh từ dd/MM/yyyy
        LocalDate dob;
        try {
            dob = LocalDate.parse(dateOfBirthStr, DateTimeFormatter.ofPattern("dd/MM/yyyy"));
        } catch (Exception e) {
            throw new RuntimeException("Định dạng ngày sinh không hợp lệ (dd/MM/yyyy)");
        }

        // Tìm sinh viên theo mã SV
        Student student = studentRepository.findByStudentCode(studentCode)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy sinh viên với mã số này"));

        // Kiểm tra ngày sinh
        if (!student.getDateOfBirth().equals(dob)) {
            throw new RuntimeException("Thông tin không khớp, vui lòng kiểm tra lại");
        }

        User user = student.getUser();
        if (user == null || user.getEmail() == null || user.getEmail().isBlank()) {
            throw new RuntimeException("Tài khoản không có email, vui lòng liên hệ phòng Đào tạo");
        }

        // Tạo mật khẩu mới ngẫu nhiên
        String newPassword = generatePassword();

        // Cập nhật mật khẩu trong DB
        user.setPassword(passwordEncoder.encode(newPassword));
        user.setUpdatedAt(LocalDateTime.now());
        userRepository.save(user);

        // Gửi email
        sendResetEmail(user.getEmail(), student.getFullName(), studentCode, newPassword);
    }

    private String generatePassword() {
        SecureRandom random = new SecureRandom();
        StringBuilder sb = new StringBuilder(PASSWORD_LENGTH);
        for (int i = 0; i < PASSWORD_LENGTH; i++) {
            sb.append(CHARS.charAt(random.nextInt(CHARS.length())));
        }
        return sb.toString();
    }

    private void sendResetEmail(String email, String fullName, String studentCode, String newPassword) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(email);
            message.setSubject("[Thông tin NLUers] Mật khẩu mới của bạn");
            message.setText(
                "Xin chào " + fullName + ",\n\n" +
                "Chúng tôi đã nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn.\n\n" +
                "Mã số sinh viên: " + studentCode + "\n" +
                "Mật khẩu mới: " + newPassword + "\n\n" +
                "Vui lòng đăng nhập và đổi mật khẩu ngay sau khi nhận được email này.\n\n" +
                "Trân trọng,\nHệ thống Thông tin NLUers\nTrường Đại học Nông Lâm TP.HCM"
            );
            mailSender.send(message);
            log.info("Password reset email sent to: {}", email);
        } catch (Exception e) {
            log.error("Failed to send email to {}: {}", email, e.getMessage());
            throw new RuntimeException("Không thể gửi email, vui lòng thử lại sau");
        }
    }
}
