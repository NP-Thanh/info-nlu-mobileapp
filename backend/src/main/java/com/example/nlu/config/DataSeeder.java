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
    private final SectionRepository sectionRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final ScheduleRepository scheduleRepository;
    private final GradeRepository gradeRepository;
    private final SemesterSummaryRepository semesterSummaryRepository;

    @Override
    @Transactional
    public void run(String... args) {
        if (userRepository.findByUsername("22130255").isPresent()) {
            log.info("Seed skipped — data already exists");
            return;
        }

        // 1. Program
        Program program = new Program();
        program.setFaculty("Công nghệ hóa học");
        program.setMajor("Công nghệ hóa học");
        program.setSpecialization("Công nghệ hóa học");
        program.setEducationType("Đại học");
        programRepository.save(program);

        // 2. User
        User user = new User();
        user.setUsername("22130255");
        user.setPassword(passwordEncoder.encode("22130255"));
        user.setEmail("22130255@st.hcmuaf.edu.n");
        user.setRole(Role.STUDENT);
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());
        userRepository.save(user);

        // 3. Student
        Student student = new Student();
        student.setUser(user);
        student.setStudentCode("22130255");
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
        student.setStatus(StudentStatus.ACTIVE);
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

        // 6. Seed điểm và tổng kết học kỳ
        seedGradesAndSummaries(student);

        log.info("Seeded student 22130255 - Nguyễn Phúc Thạnh with multi-semester schedules");
    }

    private void seedSchedules(Student student) {
        seedSemester(student, "1", "2022-2023",
                LocalDate.of(2022, 9, 4), LocalDate.of(2023, 1, 8),
                List.of(
                    cs("COMP1011", "Nhập môn lập trình", 3, "Trần Văn An", "P1-Phòng máy", 2, 1),
                    cs("MATH1011", "Giải tích 1", 3, "Nguyễn Thị Bình", "GD 101", 3, 2),
                    cs("PHYS1011", "Vật lý đại cương", 2, "Lê Văn Cường", "GD 201", 4, 1),
                    cs("ENG1011", "Tiếng Anh cơ bản 1", 3, "Phạm Thị Dung", "PH 101", 5, 3),
                    cs("POLI1011", "Triết học Mác-Lênin", 3, "Hoàng Văn Em", "GD 301", 6, 2)
                ));

        seedSemester(student, "2", "2022-2023",
                LocalDate.of(2023, 2, 13), LocalDate.of(2023, 6, 18),
                List.of(
                    cs("COMP1021", "Lập trình hướng đối tượng", 3, "Trần Văn An", "P1-Phòng máy", 2, 1),
                    cs("MATH1021", "Giải tích 2", 3, "Nguyễn Thị Bình", "GD 101", 4, 2),
                    cs("COMP1031", "Cấu trúc dữ liệu", 3, "Vũ Minh Phúc", "P2-Phòng máy", 3, 3),
                    cs("ENG1021", "Tiếng Anh cơ bản 2", 3, "Phạm Thị Dung", "PH 101", 5, 1),
                    cs("POLI1021", "Kinh tế chính trị", 2, "Hoàng Văn Em", "GD 301", 6, 4)
                ));

        seedSemester(student, "1", "2023-2024",
                LocalDate.of(2023, 9, 4), LocalDate.of(2024, 1, 7),
                List.of(
                    cs("COMP2011", "Lập trình web", 3, "Nguyễn Văn Hùng", "P1-Phòng máy", 2, 1),
                    cs("COMP2021", "Cơ sở dữ liệu", 3, "Lê Thị Lan", "GD 102", 3, 2),
                    cs("COMP2031", "Mạng máy tính", 3, "Trần Minh Khoa", "GD 201", 4, 3),
                    cs("MATH2011", "Xác suất thống kê", 3, "Nguyễn Thị Bình", "GD 101", 5, 1),
                    cs("ENG2011", "Tiếng Anh chuyên ngành", 3, "Nguyễn Thị Mai", "PH 302", 6, 2)
                ));

        seedSemester(student, "2", "2023-2024",
                LocalDate.of(2024, 2, 19), LocalDate.of(2024, 6, 23),
                List.of(
                    cs("COMP3011", "Thương mại điện tử", 3, "Khương Hải Châu", "P1-Phòng máy", 2, 1),
                    cs("COMP3021", "Phân tích hệ thống", 3, "Lê Văn Vang", "GD 102", 2, 2),
                    cs("ENG3011", "Tiếng Anh chuyên ngành", 3, "Nguyễn Thị Mai", "PH 302", 4, 3),
                    cs("COMP3031", "Lập trình di động", 3, "Trần Minh Khoa", "P2-Phòng máy", 5, 1),
                    cs("COMP3041", "An toàn thông tin", 3, "Nguyễn Văn Hùng", "GD 201", 6, 2)
                ));

        seedSemester(student, "1", "2024-2025",
                LocalDate.of(2024, 9, 2), LocalDate.of(2025, 1, 5),
                List.of(
                    cs("COMP4011", "Trí tuệ nhân tạo", 3, "Phạm Văn Đức", "P1-Phòng máy", 2, 1),
                    cs("COMP4021", "Học máy", 3, "Lê Thị Lan", "P2-Phòng máy", 3, 2),
                    cs("COMP4031", "Xử lý ngôn ngữ tự nhiên", 3, "Trần Văn An", "GD 102", 4, 3),
                    cs("COMP4041", "Kiến trúc phần mềm", 3, "Nguyễn Văn Hùng", "GD 201", 5, 1),
                    cs("ENG4011", "Tiếng Anh nâng cao", 3, "Nguyễn Thị Mai", "PH 302", 6, 2)
                ));

        seedSemester(student, "2", "2024-2025",
                LocalDate.of(2025, 2, 17), LocalDate.of(2025, 6, 22),
                List.of(
                    cs("COMP5011", "Đồ án tốt nghiệp", 10, "Trần Minh Khoa", "P1-Phòng máy", 2, 1),
                    cs("COMP5021", "Kiểm thử phần mềm", 3, "Lê Văn Vang", "GD 102", 3, 2),
                    cs("COMP5031", "Điện toán đám mây", 3, "Phạm Văn Đức", "P2-Phòng máy", 4, 3),
                    cs("COMP5041", "Quản lý dự án CNTT", 3, "Khương Hải Châu", "GD 201", 5, 1),
                    cs("ENG5011", "Tiếng Anh chuyên ngành nâng cao", 2, "Nguyễn Thị Mai", "PH 302", 6, 4)
                ));
    }

    /**
     * Seed một học kỳ: tạo Course → Section → Enrollment → Schedule cho mỗi môn.
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

            // Section: nhóm học phần (course + semester + year)
            Section section = new Section();
            section.setCourse(course);
            section.setSemester(semester);
            section.setAcademicYear(academicYear);
            section.setStartDate(startDate);
            section.setEndDate(endDate);
            section.setIsLab(false);
            sectionRepository.save(section);

            // Enrollment: sinh viên đăng ký section này
            Enrollment enrollment = new Enrollment();
            enrollment.setStudent(student);
            enrollment.setSection(section);
            enrollmentRepository.save(enrollment);

            // Schedule: thông tin lịch học của section
            Schedule schedule = new Schedule();
            schedule.setSection(section);
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

    // ─── Grade & Summary seeding ─────────────────────────────────────────────

    private void seedGradesAndSummaries(Student student) {
        seedGrades(student, "1", "2022-2023", List.of(
            gd("COMP1011", 8.0f, 7.5f, 7.7f, 3.3f, "ĐẠT"),
            gd("MATH1011", 7.0f, 6.5f, 6.7f, 2.7f, "ĐẠT"),
            gd("PHYS1011", 6.5f, 5.0f, 5.5f, 1.5f, "NỢ"),
            gd("ENG1011", 8.5f, 8.0f, 8.2f, 3.7f, "ĐẠT"),
            gd("POLI1011", 7.5f, 7.0f, 7.2f, 3.0f, "ĐẠT")
        ));
        seedSummary(student, "1", "2022-2023", 7.45f, 3.18f, 7.45f, 3.18f, 12, 12);

        seedGrades(student, "2", "2022-2023", List.of(
            gd("COMP1021", 8.5f, 8.0f, 8.2f, 3.7f, "ĐẠT"),
            gd("MATH1021", 6.5f, 5.5f, 5.9f, 1.9f, "NỢ"),
            gd("COMP1031", 7.5f, 7.0f, 7.2f, 3.0f, "ĐẠT"),
            gd("ENG1021", 8.0f, 7.5f, 7.7f, 3.3f, "ĐẠT"),
            gd("POLI1021", 7.0f, 6.5f, 6.7f, 2.7f, "ĐẠT")
        ));
        seedSummary(student, "2", "2022-2023", 7.45f, 3.18f, 7.45f, 3.18f, 11, 23);

        seedGrades(student, "1", "2023-2024", List.of(
            gd("COMP2011", 8.0f, 7.5f, 7.7f, 3.3f, "ĐẠT"),
            gd("COMP2021", 9.0f, 8.5f, 8.7f, 4.0f, "ĐẠT"),
            gd("COMP2031", 7.5f, 7.0f, 7.2f, 3.0f, "ĐẠT"),
            gd("MATH2011", 7.0f, 6.5f, 6.7f, 2.7f, "ĐẠT"),
            gd("ENG2011", 8.5f, 8.0f, 8.2f, 3.7f, "ĐẠT")
        ));
        seedSummary(student, "1", "2023-2024", 7.70f, 3.34f, 7.55f, 3.25f, 15, 38);

        seedGrades(student, "2", "2023-2024", List.of(
            gd("COMP3011", 8.5f, 7.0f, 7.6f, 3.0f, "ĐẠT"),
            gd("COMP3021", 9.0f, 8.5f, 8.7f, 4.0f, "ĐẠT"),
            gd("ENG3011", 7.5f, 8.0f, 7.8f, 3.3f, "ĐẠT"),
            gd("COMP3031", 6.0f, 5.0f, 5.4f, 1.5f, "NỢ"),
            gd("COMP3041", 8.0f, 7.5f, 7.7f, 3.3f, "ĐẠT")
        ));
        seedSummary(student, "2", "2023-2024", 7.44f, 3.11f, 7.52f, 3.25f, 12, 50);

        seedGrades(student, "1", "2024-2025", List.of(
            gd("COMP4011", 8.5f, 8.0f, 8.2f, 3.7f, "ĐẠT"),
            gd("COMP4021", 9.0f, 8.5f, 8.7f, 4.0f, "ĐẠT"),
            gd("COMP4031", 7.5f, 7.0f, 7.2f, 3.0f, "ĐẠT"),
            gd("COMP4041", 8.0f, 7.5f, 7.7f, 3.3f, "ĐẠT"),
            gd("ENG4011", 7.0f, 6.5f, 6.7f, 2.7f, "ĐẠT")
        ));
        seedSummary(student, "1", "2024-2025", 7.70f, 3.34f, 7.58f, 3.27f, 15, 65);

        log.info("Seeded grades for all semesters");
    }

    private void seedGrades(Student student, String semester, String academicYear,
                             List<GradeData> gradeList) {
        List<Enrollment> enrollments =
                enrollmentRepository.findByStudentAndSemester(student.getStudentCode(), academicYear, semester);

        for (GradeData gd : gradeList) {
            enrollments.stream()
                    .filter(e -> e.getSection().getCourse().getCourseCode().equals(gd.courseCode())
                            && !Boolean.TRUE.equals(e.getSection().getIsLab()))
                    .findFirst()
                    .ifPresent(enrollment -> {
                        Grade grade = new Grade();
                        grade.setEnrollment(enrollment);
                        grade.setProcessScore(gd.processScore());
                        grade.setExamScore(gd.examScore());
                        grade.setFinalScore10(gd.finalScore10());
                        grade.setFinalScore4(gd.finalScore4());
                        grade.setResult(gd.result());
                        gradeRepository.save(grade);
                    });
        }
    }

    private void seedSummary(Student student, String semester, String academicYear,
                              float gpa10, float gpa4, float cumGpa10, float cumGpa4,
                              int semCredits, int cumCredits) {
        SemesterSummary ss = new SemesterSummary();
        ss.setStudent(student);
        ss.setSemester(semester);
        ss.setAcademicYear(academicYear);
        ss.setGpa10(gpa10);
        ss.setGpa4(gpa4);
        ss.setCumulativeGpa10(cumGpa10);
        ss.setCumulativeGpa4(cumGpa4);
        ss.setSemesterCredits(semCredits);
        ss.setCumulativeCredits(cumCredits);
        semesterSummaryRepository.save(ss);
    }

    private static GradeData gd(String courseCode, float process, float exam,
                                  float score10, float score4, String result) {
        return new GradeData(courseCode, process, exam, score10, score4, result);
    }

    private record GradeData(
            String courseCode,
            float processScore, float examScore,
            float finalScore10, float finalScore4,
            String result) {}
}
