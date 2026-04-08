//package com.example.nlu.config;
//
//import com.example.nlu.entity.Role;
//import com.example.nlu.entity.Student;
//import com.example.nlu.entity.User;
//import com.example.nlu.repo.StudentRepository;
//import com.example.nlu.repo.UserRepository;
//import lombok.RequiredArgsConstructor;
//import lombok.extern.slf4j.Slf4j;
//import org.springframework.boot.CommandLineRunner;
//import org.springframework.security.crypto.password.PasswordEncoder;
//import org.springframework.stereotype.Component;
//
//import java.time.LocalDate;
//import java.time.LocalDateTime;
//
//@Slf4j
//@Component
//@RequiredArgsConstructor
//public class DataSeeder implements CommandLineRunner {
//
//    private final UserRepository userRepository;
//    private final StudentRepository studentRepository;
//    private final PasswordEncoder passwordEncoder;
//
//    @Override
//    public void run(String... args) {
//        seedStudent(
//            "22130259",
//            "22130259",                     // mật khẩu mặc định = mã SV
//            "22130259@st.hcmuaf.edu.vn",
//            "Nguyễn Phúc Thạnh",
//            LocalDate.of(2004, 11, 2),
//            "Nam",
//            "0826661039",
//            "086204000345",
//            "Kinh",
//            "Vĩnh Long",
//            2022, 2026,
//            "Đang học"
//        );
//    }
//
//    private void seedStudent(String username, String rawPassword, String email,
//                              String fullName, LocalDate dob, String gender,
//                              String phone, String cccd, String ethnicity,
//                              String placeOfBirth, int startYear, int endYear, String status) {
//        if (userRepository.findByUsername(username).isPresent()) {
//            log.info("Seed skipped — user '{}' already exists", username);
//            return;
//        }
//
//        User user = new User();
//        user.setUsername(username);
//        user.setPassword(passwordEncoder.encode(rawPassword));
//        user.setEmail(email);
//        user.setRole(Role.STUDENT);
//        user.setCreatedAt(LocalDateTime.now());
//        user.setUpdatedAt(LocalDateTime.now());
//        userRepository.save(user);
//
//        Student student = new Student();
//        student.setUser(user);
//        student.setStudentCode(username);
//        student.setFullName(fullName);
//        student.setDateOfBirth(dob);
//        student.setGender(gender);
//        student.setPhone(phone);
//        student.setCccd(cccd);
//        student.setEthnicity(ethnicity);
//        student.setPlaceOfBirth(placeOfBirth);
//        student.setStartYear(startYear);
//        student.setEndYear(endYear);
//        student.setStatus(status);
//        studentRepository.save(student);
//
//        log.info("Seeded student: {} - {}", username, fullName);
//    }
//}
