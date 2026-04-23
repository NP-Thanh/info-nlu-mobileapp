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
    private final CourseRepository courseRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final ScheduleRepository scheduleRepository;

    @Override
    @Transactional
    public void run(String... args) {
        if (userRepository.findByUsername("22130259").isPresent()) {
            log.info("Seed skipped — data already exists");
            return;
        }

        // 1. Program
        Program program = new Program();
        program.setFaculty("Công nghệ thông tin");
        program.setMajor("Công nghệ thông tin");
        program.setSpecialization("Công nghệ thông tin");
        program.setEducationType("Đại học");
        programRepository.save(program);

        // 2. User
        User user = new User();
        user.setUsername("22130259");
        user.setPassword(passwordEncoder.encode("22130259"));
        user.setEmail("22130259@st.hcmuaf.edu.vn");
        user.setRole(Role.STUDENT);
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());
        userRepository.save(user);

        // 3. Student
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

        // 4. StudentProgram
        StudentProgram sp = new StudentProgram();
        sp.setStudent(student);
        sp.setProgram(program);
        sp.setClassName("DH22DTB");
        sp.setStartYear(2022);
        sp.setEndYear(2026);
        studentProgramRepository.save(sp);

        // 5. Seed TKB nhiều học kỳ
        seedSchedules(student);

        log.info("Seeded student 22130259 - Nguyễn Phúc Thạnh with multi-semester schedules");
    }

    private void seedSchedules(Student student) {
        // HK1 2022-2023
        seedSemester(student, "1", "2022-2023",
                LocalDate.of(2022, 9, 4), LocalDate.of(2023, 1, 8),
                List.of(
                    cs("COMP101", "Nhập môn lập trình", 3, "Trần Văn An", "P1-Phòng máy", 2, 1),
                    cs("MATH101", "Giải tích 1", 3, "Nguyễn Thị Bình", "GD 101", 3, 2),
                    cs("PHYS101", "Vật lý đại cương", 2, "Lê Văn Cường", "GD 201", 4, 1),
                    cs("ENG101", "Tiếng Anh cơ bản 1", 3, "Phạm Thị Dung", "PH 101", 5, 3),
                    cs("POLI101", "Triết học Mác-Lênin", 3, "Hoàng Văn Em", "GD 301", 6, 2)
                ));

        // HK2 2022-2023
        seedSemester(student, "2", "2022-2023",
                LocalDate.of(2023, 2, 13), LocalDate.of(2023, 6, 18),
                List.of(
                    cs("COMP102", "Lập trình hướng đối tượng", 3, "Trần Văn An", "P1-Phòng máy", 2, 1),
                    cs("MATH102", "Giải tích 2", 3, "Nguyễn Thị Bình", "GD 101", 4, 2),
                    cs("COMP103", "Cấu trúc dữ liệu", 3, "Vũ Minh Phúc", "P2-Phòng máy", 3, 3),
                    cs("ENG102", "Tiếng Anh cơ bản 2", 3, "Phạm Thị Dung", "PH 101", 5, 1),
                    cs("POLI102", "Kinh tế chính trị", 2, "Hoàng Văn Em", "GD 301", 6, 4)
                ));

        // HK1 2023-2024
        seedSemester(student, "1", "2023-2024",
                LocalDate.of(2023, 9, 4), LocalDate.of(2024, 1, 7),
                List.of(
                    cs("COMP201", "Lập trình web", 3, "Nguyễn Văn Hùng", "P1-Phòng máy", 2, 1),
                    cs("COMP202", "Cơ sở dữ liệu", 3, "Lê Thị Lan", "GD 102", 3, 2),
                    cs("COMP203", "Mạng máy tính", 3, "Trần Minh Khoa", "GD 201", 4, 3),
                    cs("MATH201", "Xác suất thống kê", 3, "Nguyễn Thị Bình", "GD 101", 5, 1),
                    cs("ENG201", "Tiếng Anh chuyên ngành", 3, "Nguyễn Thị Mai", "PH 302", 6, 2)
                ));

        // HK2 2023-2024 (theo ảnh mẫu)
        seedSemester(student, "2", "2023-2024",
                LocalDate.of(2024, 2, 19), LocalDate.of(2024, 6, 23),
                List.of(
                    cs("COMP301", "Thương mại điện tử", 3, "Khương Hải Châu", "P1-Phòng máy", 2, 1),
                    cs("COMP302", "Phân tích hệ thống", 3, "Lê Văn Vang", "GD 102", 2, 2),
                    cs("ENG301", "Tiếng Anh chuyên ngành", 3, "Nguyễn Thị Mai", "PH 302", 4, 3),
                    cs("COMP303", "Lập trình di động", 3, "Trần Minh Khoa", "P2-Phòng máy", 5, 1),
                    cs("COMP304", "An toàn thông tin", 3, "Nguyễn Văn Hùng", "GD 201", 6, 2)
                ));

        // HK1 2024-2025
        seedSemester(student, "1", "2024-2025",
                LocalDate.of(2024, 9, 2), LocalDate.of(2025, 1, 5),
                List.of(
                    cs("COMP401", "Trí tuệ nhân tạo", 3, "Phạm Văn Đức", "P1-Phòng máy", 2, 1),
                    cs("COMP402", "Học máy", 3, "Lê Thị Lan", "P2-Phòng máy", 3, 2),
                    cs("COMP403", "Xử lý ngôn ngữ tự nhiên", 3, "Trần Văn An", "GD 102", 4, 3),
                    cs("COMP404", "Kiến trúc phần mềm", 3, "Nguyễn Văn Hùng", "GD 201", 5, 1),
                    cs("ENG401", "Tiếng Anh nâng cao", 3, "Nguyễn Thị Mai", "PH 302", 6, 2)
                ));

        // HK2 2024-2025 — học kỳ mới nhất, hiển thị mặc định
        seedSemester(student, "2", "2024-2025",
                LocalDate.of(2025, 2, 17), LocalDate.of(2025, 6, 22),
                List.of(
                    cs("COMP501", "Đồ án tốt nghiệp", 10, "Trần Minh Khoa", "P1-Phòng máy", 2, 1),
                    cs("COMP502", "Kiểm thử phần mềm", 3, "Lê Văn Vang", "GD 102", 3, 2),
                    cs("COMP503", "Điện toán đám mây", 3, "Phạm Văn Đức", "P2-Phòng máy", 4, 3),
                    cs("COMP504", "Quản lý dự án CNTT", 3, "Khương Hải Châu", "GD 201", 5, 1),
                    cs("ENG501", "Tiếng Anh chuyên ngành nâng cao", 2, "Nguyễn Thị Mai", "PH 302", 6, 4)
                ));
    }

    /**
     * Seed một học kỳ: tạo Course → Enrollment → Schedule cho mỗi môn.
     */
    private void seedSemester(Student student, String semester, String academicYear,
                               LocalDate startDate, LocalDate endDate,
                               List<CourseData> courses) {
        for (CourseData c : courses) {
            // Course
            Course course = new Course();
            course.setCourseCode(c.code());
            course.setCourseName(c.name());
            course.setCredits(c.credits());
            courseRepository.save(course);

            // Enrollment: liên kết student ↔ course, chứa thông tin học kỳ
            Enrollment enrollment = new Enrollment();
            enrollment.setStudent(student);
            enrollment.setCourse(course);
            enrollment.setSemester(semester);
            enrollment.setAcademicYear(academicYear);
            enrollment.setStartDate(startDate);
            enrollment.setEndDate(endDate);
            enrollment.setAttempt(1);
            enrollmentRepository.save(enrollment);

            // Schedule: liên kết với enrollment, chứa thông tin lịch học
            Schedule schedule = new Schedule();
            schedule.setEnrollment(enrollment);
            schedule.setLecturer(c.lecturer());
            schedule.setRoom(c.room());
            schedule.setDayOfWeek(c.dayOfWeek());
            schedule.setPeriod(c.period());
            scheduleRepository.save(schedule);
        }
        log.info("Seeded HK{} {} — {} courses", semester, academicYear, courses.size());
    }

    private static CourseData cs(String code, String name, int credits,
                                  String lecturer, String room, int dow, int period) {
        return new CourseData(code, name, credits, lecturer, room, dow, period);
    }

    private record CourseData(
            String code, String name, int credits,
            String lecturer, String room,
            int dayOfWeek, int period) {}
}
