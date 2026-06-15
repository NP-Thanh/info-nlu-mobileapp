package com.example.nlu.config;

import com.example.nlu.entity.*;
import com.example.nlu.repo.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

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
    @Transactional
    public void run(String... args) {
        seedPrograms();
        seedAdmin();
        seedStudent22130259();
    }

    // ─── PROGRAMS ────────────────────────────────────────────────────────────

    private void seedPrograms() {
        if (programRepository.count() > 0) {
            log.info("Programs already seeded, skipping.");
            return;
        }

        List<String[]> data = List.of(
            // {faculty, major, specialization}
            new String[]{"Nông học", "Bảo vệ thực vật", "Bảo vệ thực vật"},
            new String[]{"Kinh tế", "Bất động sản", "Bất động sản"},
            new String[]{"Môi trường và Tài nguyên", "Cảnh quan và kỹ thuật hoa viên", "Cảnh quan và kỹ thuật hoa viên"},
            new String[]{"Môi trường và Tài nguyên", "Cảnh quan và kỹ thuật hoa viên", "Thiết kế cảnh quan"},
            new String[]{"Chăn nuôi - Thú y", "Chăn nuôi", "Chăn nuôi"},
            new String[]{"Nông học", "CN rau hoa quả và cảnh quan", "CN rau hoa quả và cảnh quan"},
            new String[]{"Cơ khí - Công nghệ", "CNKT năng lượng tái tạo", "CNKT năng lượng tái tạo"},
            new String[]{"Lâm nghiệp", "Công nghệ chế biến lâm sản", "Chế biến lâm sản"},
            new String[]{"Lâm nghiệp", "Công nghệ chế biến lâm sản", "Công nghệ gỗ – giấy"},
            new String[]{"Lâm nghiệp", "Công nghệ chế biến lâm sản", "Thiết kế đồ gỗ nội thất"},
            new String[]{"Thủy sản", "Công nghệ chế biến thuỷ sản", "Công nghệ chế biến thuỷ sản"},
            new String[]{"Cơ khí - Công nghệ", "Công nghệ kỹ thuật cơ điện tử", "Công nghệ kỹ thuật cơ điện tử"},
            new String[]{"Cơ khí - Công nghệ", "Công nghệ kỹ thuật cơ khí", "Cơ khí chế biển bảo quản nông sản thực phẩm"},
            new String[]{"Cơ khí - Công nghệ", "Công nghệ kỹ thuật cơ khí", "Cơ khí nông lâm"},
            new String[]{"Cơ khí - Công nghệ", "Công nghệ kỹ thuật cơ khí", "Công nghệ kỹ thuật cơ khí (Chất lượng cao)"},
            new String[]{"Cơ khí - Công nghệ", "Công nghệ kỹ thuật hóa học", "Công nghệ kỹ thuật hóa học"},
            new String[]{"Cơ khí - Công nghệ", "Công nghệ kỹ thuật nhiệt", "Công nghệ kỹ thuật nhiệt"},
            new String[]{"Cơ khí - Công nghệ", "Công nghệ kỹ thuật Ô tô", "Công nghệ kỹ thuật Ô tô"},
            new String[]{"Công nghệ Sinh học", "Công nghệ sinh học", "Công nghệ sinh học"},
            new String[]{"Công nghệ Sinh học", "Công nghệ sinh học", "Công nghệ sinh học môi trường"},
            new String[]{"Công nghệ Sinh học", "Công nghệ sinh học", "Công nghệ sinh học (Chất lượng cao)"},
            new String[]{"Công nghệ Thông tin", "Công nghệ thông tin", "Công nghệ thông tin"},
            new String[]{"Công nghệ Thực phẩm", "Công nghệ thực phẩm", "Bảo quản chế biến nông sản thực phẩm"},
            new String[]{"Công nghệ Thực phẩm", "Công nghệ thực phẩm", "Bảo quản chế biến NSTP và dinh dưỡng người"},
            new String[]{"Công nghệ Thực phẩm", "Công nghệ thực phẩm", "Bảo quản chế biến NSTP và vi sinh thực phẩm"},
            new String[]{"Công nghệ Thông tin", "Hệ thống thông tin", "Hệ thống thông tin"},
            new String[]{"Kinh tế", "Kế toán", "Kế toán"},
            new String[]{"Môi trường và Tài nguyên", "Khoa học môi trường", "Khoa học môi trường"},
            new String[]{"Kinh tế", "Kinh doanh nông nghiệp", "Kinh doanh nông nghiệp"},
            new String[]{"Kinh tế", "Kinh tế", "Kinh tế nông nghiệp"},
            new String[]{"Kinh tế", "Kinh tế", "Kinh tế tài nguyên môi trường"},
            new String[]{"Cơ khí - Công nghệ", "KT điều khiển và tự động hóa", "KT điều khiển và tự động hóa"},
            new String[]{"Môi trường và Tài nguyên", "Kỹ thuật môi trường", "Kỹ thuật môi trường"},
            new String[]{"Môi trường và Tài nguyên", "Kỹ thuật môi trường", "Kỹ thuật môi trường (Chất lượng cao)"},
            new String[]{"Lâm nghiệp", "Lâm học", "Lâm sinh"},
            new String[]{"Lâm nghiệp", "Lâm học", "Nông lâm kết hợp"},
            new String[]{"Lâm nghiệp", "Lâm nghiệp đô thị", "Lâm nghiệp đô thị"},
            new String[]{"Ngoại ngữ - Sư phạm", "Ngôn ngữ anh", "Ngôn ngữ anh"},
            new String[]{"Nông học", "Nông học", "Nông học"},
            new String[]{"Thủy sản", "Nuôi trồng thủy sản", "Nuôi trồng thủy sản"},
            new String[]{"Thủy sản", "Nuôi trồng thủy sản", "Ngư y (Bệnh học thủy sản)"},
            new String[]{"Thủy sản", "Nuôi trồng thủy sản", "Kinh tế – Quản lý nuôi trồng thủy sản"},
            new String[]{"Nông học", "Phát triển nông thôn", "Phát triển nông thôn"},
            new String[]{"Môi trường và Tài nguyên", "Quản lý đất đai", "Quản lý đất đai"},
            new String[]{"Môi trường và Tài nguyên", "Quản lý đất đai", "Công nghệ địa chính"},
            new String[]{"Môi trường và Tài nguyên", "Quản lý đất đai", "Địa chính và quản lý đô thị"},
            new String[]{"Lâm nghiệp", "Quản lý tài nguyên rừng", "Quản lý tài nguyên rừng"},
            new String[]{"Môi trường và Tài nguyên", "Quản lý tài nguyên và môi trường", "Quản lý tài nguyên và môi trường"},
            new String[]{"Kinh tế", "Quản trị kinh doanh", "Quản trị kinh doanh (tổng hợp)"},
            new String[]{"Kinh tế", "Quản trị kinh doanh", "Quản trị kinh doanh thương mại"},
            new String[]{"Kinh tế", "Quản trị kinh doanh", "Quản trị tài chính"},
            new String[]{"Sư phạm Kỹ thuật", "Sư phạm kỹ thuật nông nghiệp", "Sư phạm kỹ thuật nông nghiệp"},
            new String[]{"Môi trường và Tài nguyên", "Tài nguyên và du lịch sinh thái", "Tài nguyên và du lịch sinh thái"},
            new String[]{"Chăn nuôi - Thú y", "Thú y", "Bác sĩ Thú y"},
            new String[]{"Chăn nuôi - Thú y", "Thú y", "Dược Thú y"},
            new String[]{"Chăn nuôi - Thú y", "Thú y", "Bác sĩ Thú y (Chương trình tiên tiến)"}
        );

        for (String[] row : data) {
            Program p = new Program();
            p.setFaculty(row[0]);
            p.setMajor(row[1]);
            p.setSpecialization(row[2]);
            p.setEducationType("Đại học");
            programRepository.save(p);
        }

        log.info("Seeded {} programs.", data.size());
    }

    // ─── ADMIN USER ──────────────────────────────────────────────────────────

    private void seedAdmin() {
        if (userRepository.findByUsername("admin").isPresent()) {
            log.info("Admin already exists, skipping.");
            return;
        }

        User admin = new User();
        admin.setUsername("admin");
        admin.setPassword(passwordEncoder.encode("123456"));
        admin.setEmail("bi2004npt@gmail.com");
        admin.setRole(Role.ADMIN);
        admin.setIsDeleted(false);
        admin.setCreatedAt(LocalDateTime.now());
        admin.setUpdatedAt(LocalDateTime.now());
        userRepository.save(admin);

        log.info("Seeded admin user.");
    }

    // ─── STUDENT 22130259 ────────────────────────────────────────────────────

    private void seedStudent22130259() {
        if (userRepository.findByUsername("22130259").isPresent()) {
            log.info("Student 22130259 already exists, skipping.");
            return;
        }

        // Lấy program CNTT
        Program program = programRepository
                .findAll()
                .stream()
                .filter(p -> "Công nghệ thông tin".equals(p.getSpecialization()))
                .findFirst()
                .orElseGet(() -> {
                    Program p = new Program();
                    p.setFaculty("Công nghệ Thông tin");
                    p.setMajor("Công nghệ thông tin");
                    p.setSpecialization("Công nghệ thông tin");
                    p.setEducationType("Đại học");
                    return programRepository.save(p);
                });

        User user = new User();
        user.setUsername("22130259");
        user.setPassword(passwordEncoder.encode("22130259"));
        user.setEmail("22130259@st.hcmuaf.edu.vn");
        user.setRole(Role.STUDENT);
        user.setIsDeleted(false);
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());
        userRepository.save(user);

        Student student = new Student();
        student.setUser(user);
        student.setStudentCode("22130259");
        student.setFullName("Nguyễn Phúc Thành");
        student.setDateOfBirth(LocalDate.of(2004, 1, 1));
        student.setGender("Nam");
        student.setStartYear(2022);
        student.setEndYear(2026);
        student.setStatus(StudentStatus.ACTIVE);
        studentRepository.save(student);

        StudentProgram sp = new StudentProgram();
        sp.setStudent(student);
        sp.setProgram(program);
        sp.setClassName("DH22TT");
        sp.setStartYear(2022);
        sp.setEndYear(2026);
        studentProgramRepository.save(sp);

        log.info("Seeded student 22130259.");
    }
}
