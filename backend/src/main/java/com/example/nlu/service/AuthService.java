package com.example.nlu.service;

import com.example.nlu.entity.Student;
import com.example.nlu.repo.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final StudentRepository studentRepository;

    public Student login(String studentId, String password) {
        Student student = studentRepository.findByStudentId(studentId)
                .orElseThrow(() -> new RuntimeException("Sai mã số sinh viên hoặc mật khẩu"));

        // NOTE: dùng BCrypt trong production, đây là demo plain text
        if (!student.getPassword().equals(password)) {
            throw new RuntimeException("Sai mã số sinh viên hoặc mật khẩu");
        }
        return student;
    }
}
