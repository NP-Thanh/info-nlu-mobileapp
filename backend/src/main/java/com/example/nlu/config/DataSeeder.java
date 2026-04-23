package com.example.nlu.config;

import com.example.nlu.entity.*;
import com.example.nlu.repo.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Slf4j
@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final ProgramRepository programRepository;
    private final StudentProgramRepository studentProgramRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        if (userRepository.findByUsername("22130259").isPresent()) {
            log.info("Seed skipped — data already exists");
            return;
        }

        // 1. Tạo Program
        Program program = new Program();
        program.setFaculty("Công nghệ thông tin");
        program.setMajor("Công nghệ thông tin");
        program.setSpecialization("Công nghệ thông tin");
        program.setEducationType("Đại học");
        programRepository.save(program);

        // 2. Tạo User
        User user = new User();
        user.setUsername("22130259");
        user.setPassword(passwordEncoder.encode("22130259"));
        user.setEmail("22130259@st.hcmuaf.edu.vn");
        user.setRole(Role.STUDENT);
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());
        userRepository.save(user);

        // 3. Tạo Student
        Student student = new Student();
        student.setUser(user);
        student.setStudentCode("22130259");
        student.setFullName("Nguyễn Phúc Thạnh");
        student.setDateOfBirth(LocalDate.of(2004, 11, 2));
        student.setGender("Nam");
        student.setPhone("0826661039");
        student.setCccd("0123456789");
        student.setEthnicity("Kinh");
        student.setReligion("Không");
        student.setNationality("Việt Nam");
        student.setPlaceOfBirth("TP. Hồ Chí Minh");
        student.setStartYear(2022);
        student.setEndYear(2026);
        student.setStatus("Đang học");
        studentRepository.save(student);

        // 4. Tạo StudentProgram
        StudentProgram sp = new StudentProgram();
        sp.setStudent(student);
        sp.setProgram(program);
        sp.setClassName("DH22DTB");
        sp.setStartYear(2022);
        sp.setEndYear(2026);
        studentProgramRepository.save(sp);

        log.info("Seeded student: 22130259 - Nguyễn Phúc Thạnh");
    }
}
