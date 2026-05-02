package com.example.nlu.service;

import com.example.nlu.entity.*;
import com.example.nlu.repo.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import okhttp3.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatbotService {

    private final StudentRepository studentRepository;
    private final StudentProgramRepository studentProgramRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final GradeRepository gradeRepository;
    private final ScheduleRepository scheduleRepository;
    private final SemesterSummaryRepository semesterSummaryRepository;
    private final ChatbotLogRepository chatbotLogRepository;

    @Value("${openai.api.key}")
    private String openAiApiKey;

    @Value("${openai.model:gpt-4o-mini}")
    private String openAiModel;

    private static final String OPENAI_URL = "https://api.openai.com/v1/chat/completions";

    private static final Map<Integer, String> DAY_NAMES = Map.of(
        2, "Thứ Hai", 3, "Thứ Ba", 4, "Thứ Tư",
        5, "Thứ Năm", 6, "Thứ Sáu", 7, "Thứ Bảy", 8, "Chủ Nhật"
    );
    private static final Map<Integer, String> PERIOD_TIMES = Map.of(
        1, "07:00 - 09:15", 2, "09:30 - 11:45",
        3, "12:30 - 14:45", 4, "15:00 - 17:15"
    );

    // Entry point
    public String chat(String studentCode, String userMessage) {
        String answer;
        boolean flagged = false;

        try {
            // Detect intents (multi-intent)
            Set<Intent> intents = detectIntents(userMessage);
            log.info("Intents detected: {} for student: {}", intents, studentCode);

            // Build context from DB cho tất cả intents
            String dbContext = buildDbContext(studentCode, userMessage, intents);

            // Test chatbot
            answer = "Intents: " + intents + "\n\n" +
                     (dbContext.isBlank() ? "(Không có dữ liệu DB cho intent này)" : dbContext);

            // Build system prompt
            // String systemPrompt = buildSystemPrompt(dbContext);

            // Call OpenAI
            // answer = callOpenAi(systemPrompt, userMessage);

        } catch (OutOfScopeException e) {
            answer = e.getMessage();
            flagged = true;
        } catch (Exception e) {
            log.error("Chatbot error for student {}: {}", studentCode, e.getMessage(), e);
            answer = "Lỗi xử lý: " + e.getMessage();
        }

        saveChatLog(studentCode, userMessage, answer, flagged);
        return answer;
    }

    // Intent detection
    private enum Intent {
        STUDENT_INFO, GRADES, GPA, SCHEDULE, SCHEDULE_TODAY, FAILED_COURSES, SEMESTER, SCHOOL_INFO, UNKNOWN
    }

    private Set<Intent> detectIntents(String msg) {
        String m = msg.toLowerCase();
        Set<Intent> intents = new LinkedHashSet<>();

        if (containsAny(m, "thông tin", "họ tên", "tên", "ngày sinh", "giới tính", "mssv",
                "mã số", "lớp", "khoa", "ngành", "quê quán", "cccd", "cmnd",
                "dân tộc", "tôn giáo", "quốc tịch", "hồ sơ", "profile"))
            intents.add(Intent.STUDENT_INFO);

        if (containsAny(m, "điểm trung bình", "gpa", "tích lũy", "xếp loại học lực", "học lực",
                "trung bình tích lũy", "điểm tb"))
            intents.add(Intent.GPA);

        if (containsAny(m, "rớt môn", "trượt môn", "môn rớt", "môn trượt", "môn nào rớt",
                "môn nào trượt", "không qua môn", "môn không qua", "môn f", "điểm f",
                "thi lại", "học lại môn"))
            intents.add(Intent.FAILED_COURSES);

        if (containsAny(m, "bảng điểm", "điểm môn", "kết quả học tập", "điểm thi",
                "điểm quá trình", "điểm cuối kỳ", "điểm số", "xem điểm", "điểm học kỳ",
                "điểm các môn", "điểm hk"))
            intents.add(Intent.GRADES);

        if (m.contains("điểm") && !intents.contains(Intent.GPA)
                && !intents.contains(Intent.GRADES) && !intents.contains(Intent.FAILED_COURSES))
            intents.add(Intent.GRADES);

        if (containsAny(m, "hôm nay", "ngày hôm nay", "lịch hôm nay", "học hôm nay",
                "môn hôm nay", "tiết hôm nay", "ca hôm nay"))
            intents.add(Intent.SCHEDULE_TODAY);
        else if (containsAny(m, "lịch học", "thời khóa biểu", "tkb", "phòng học",
                "giảng viên dạy", "tiết học", "ca học", "lịch tuần"))
            intents.add(Intent.SCHEDULE);

        if (containsAny(m, "học kỳ nào", "các học kỳ", "danh sách học kỳ",
                "đã học những kỳ", "học những kỳ", "tất cả học kỳ"))
            intents.add(Intent.SEMESTER);

        if (containsAny(m, "trường", "nlu", "nông lâm", "địa chỉ", "website", "quy chế",
                "quy định", "học phí", "học bổng", "ký túc xá", "thư viện", "phòng ban",
                "ban giám hiệu", "tuyển sinh", "cách tính điểm", "thang điểm"))
            intents.add(Intent.SCHOOL_INFO);

        if (intents.isEmpty())
            intents.add(Intent.UNKNOWN);

        return intents;
    }

    private boolean containsAny(String text, String... keywords) {
        for (String kw : keywords) {
            if (text.contains(kw)) return true;
        }
        return false;
    }

    // Build DB context string
    private String buildDbContext(String studentCode, String userMessage, Set<Intent> intents) {
        Student student = studentRepository.findByStudentCode(studentCode).orElse(null);
        if (student == null) return "";

        StringBuilder ctx = new StringBuilder();
        boolean gpaAdded = false;

        for (Intent intent : intents) {
            switch (intent) {
                case STUDENT_INFO  -> ctx.append(buildStudentInfoContext(student)).append("\n");
                case GPA -> {
                    ctx.append(buildGpaContext(studentCode, userMessage)).append("\n");
                    gpaAdded = true;
                }
                case GRADES -> {
                    if (!gpaAdded) ctx.append(buildGradesContext(studentCode, userMessage)).append("\n");
                }
                case FAILED_COURSES -> ctx.append(buildFailedCoursesContext(studentCode, userMessage)).append("\n");
                case SCHEDULE_TODAY -> ctx.append(buildScheduleTodayContext(studentCode, userMessage)).append("\n");
                case SCHEDULE       -> ctx.append(buildScheduleContext(studentCode, userMessage)).append("\n");
                case SEMESTER       -> ctx.append(buildSemesterContext(studentCode)).append("\n");
                case SCHOOL_INFO, UNKNOWN -> { /* OpenAI tự trả lời */ }
            }
        }

        return ctx.toString();
    }

    private String buildStudentInfoContext(Student s) {
        Optional<StudentProgram> spOpt = studentProgramRepository.findFirstByStudent_StudentCode(s.getStudentCode());
        StringBuilder sb = new StringBuilder();
        sb.append("=== THÔNG TIN SINH VIÊN ===\n");
        sb.append("Mã số sinh viên: ").append(s.getStudentCode()).append("\n");
        sb.append("Họ và tên: ").append(s.getFullName()).append("\n");
        sb.append("Ngày sinh: ").append(s.getDateOfBirth() != null ? s.getDateOfBirth() : "Chưa cập nhật").append("\n");
        sb.append("Giới tính: ").append(nvl(s.getGender())).append("\n");
        sb.append("Số điện thoại: ").append(nvl(s.getPhone())).append("\n");
        sb.append("CCCD: ").append(nvl(s.getCccd())).append("\n");
        sb.append("Dân tộc: ").append(nvl(s.getEthnicity())).append("\n");
        sb.append("Tôn giáo: ").append(nvl(s.getReligion())).append("\n");
        sb.append("Quốc tịch: ").append(nvl(s.getNationality())).append("\n");
        sb.append("Nơi sinh: ").append(nvl(s.getPlaceOfBirth())).append("\n");
        sb.append("Trạng thái: ").append(nvl(s.getStatus())).append("\n");
        spOpt.ifPresent(sp -> {
            sb.append("Khoa: ").append(nvl(sp.getProgram().getFaculty())).append("\n");
            sb.append("Ngành: ").append(nvl(sp.getProgram().getMajor())).append("\n");
            sb.append("Chuyên ngành: ").append(nvl(sp.getProgram().getSpecialization())).append("\n");
            sb.append("Lớp: ").append(nvl(sp.getClassName())).append("\n");
            sb.append("Loại hình đào tạo: ").append(nvl(sp.getProgram().getEducationType())).append("\n");
            sb.append("Khóa học: ").append(sp.getStartYear()).append(" - ").append(sp.getEndYear()).append("\n");
        });
        return sb.toString();
    }

    private String buildGradesContext(String studentCode, String userMessage) {
        // Tìm học kỳ từ câu hỏi, nếu không thì lấy học kỳ mới nhất
        String[] semInfo = extractSemesterFromMessage(userMessage, studentCode);
        String academicYear = semInfo[0];
        String semester = semInfo[1];

        List<Enrollment> enrollments = enrollmentRepository.findByStudentAndSemester(studentCode, academicYear, semester);
        List<Grade> grades = gradeRepository.findByStudentAndSemester(studentCode, academicYear, semester);

        Map<Long, Grade> gradeMap = grades.stream()
                .collect(Collectors.toMap(g -> g.getEnrollment().getId(), g -> g));

        StringBuilder sb = new StringBuilder();
        sb.append("=== BẢNG ĐIỂM HỌC KỲ ").append(semester).append(" NĂM HỌC ").append(academicYear).append(" ===\n");

        for (Enrollment e : enrollments) {
            Grade g = gradeMap.get(e.getId());
            sb.append("Môn: ").append(e.getCourse().getCourseName())
              .append(" (").append(e.getCourse().getCourseCode()).append(")")
              .append(" - ").append(e.getCourse().getCredits()).append(" tín chỉ\n");
            if (g != null) {
                sb.append("  Điểm quá trình: ").append(g.getProcessScore() != null ? g.getProcessScore() : "Chưa có").append("\n");
                sb.append("  Điểm thi: ").append(g.getExamScore() != null ? g.getExamScore() : "Chưa có").append("\n");
                sb.append("  Điểm tổng kết (thang 10): ").append(g.getFinalScore10() != null ? g.getFinalScore10() : "Chưa có").append("\n");
                sb.append("  Điểm tổng kết (thang 4): ").append(g.getFinalScore4() != null ? g.getFinalScore4() : "Chưa có").append("\n");
                sb.append("  Kết quả: ").append(nvl(g.getResult())).append("\n");
            } else {
                sb.append("  Chưa có điểm\n");
            }
        }
        return sb.toString();
    }

    private String buildGpaContext(String studentCode, String userMessage) {
        String[] semInfo = extractSemesterFromMessage(userMessage, studentCode);
        String academicYear = semInfo[0];
        String semester = semInfo[1];

        StringBuilder sb = new StringBuilder();
        sb.append(buildGradesContext(studentCode, userMessage));

        Optional<SemesterSummary> ssOpt = semesterSummaryRepository
                .findByStudentAndSemester(studentCode, academicYear, semester);

        sb.append("\n=== KẾT QUẢ HỌC KỲ ").append(semester).append(" NĂM HỌC ").append(academicYear).append(" ===\n");
        ssOpt.ifPresentOrElse(ss -> {
            sb.append("GPA học kỳ (thang 10): ").append(ss.getGpa10() != null ? ss.getGpa10() : "Chưa có").append("\n");
            sb.append("GPA học kỳ (thang 4): ").append(ss.getGpa4() != null ? ss.getGpa4() : "Chưa có").append("\n");
            sb.append("GPA tích lũy (thang 10): ").append(ss.getCumulativeGpa10() != null ? ss.getCumulativeGpa10() : "Chưa có").append("\n");
            sb.append("GPA tích lũy (thang 4): ").append(ss.getCumulativeGpa4() != null ? ss.getCumulativeGpa4() : "Chưa có").append("\n");
            sb.append("Số tín chỉ học kỳ: ").append(ss.getSemesterCredits() != null ? ss.getSemesterCredits() : "Chưa có").append("\n");
            sb.append("Số tín chỉ tích lũy: ").append(ss.getCumulativeCredits() != null ? ss.getCumulativeCredits() : "Chưa có").append("\n");
        }, () -> sb.append("Chưa có dữ liệu tổng kết học kỳ này.\n"));

        return sb.toString();
    }

    private String buildScheduleContext(String studentCode, String userMessage) {
        String[] semInfo = extractSemesterFromMessage(userMessage, studentCode);
        String academicYear = semInfo[0];
        String semester = semInfo[1];

        List<Enrollment> enrollments = enrollmentRepository.findByStudentAndSemester(studentCode, academicYear, semester);
        if (enrollments.isEmpty()) return "Không có dữ liệu lịch học cho học kỳ này.\n";

        List<Long> ids = enrollments.stream().map(Enrollment::getId).collect(Collectors.toList());
        List<Schedule> schedules = scheduleRepository.findByEnrollmentIds(ids);

        StringBuilder sb = new StringBuilder();
        sb.append("=== THỜI KHÓA BIỂU HỌC KỲ ").append(semester).append(" NĂM HỌC ").append(academicYear).append(" ===\n");

        schedules.stream()
            .sorted(Comparator.comparingInt(Schedule::getDayOfWeek).thenComparingInt(Schedule::getPeriod))
            .forEach(s -> {
                String day = DAY_NAMES.getOrDefault(s.getDayOfWeek(), "Thứ " + s.getDayOfWeek());
                String time = PERIOD_TIMES.getOrDefault(s.getPeriod(), "Ca " + s.getPeriod());
                sb.append(day).append(" - ").append(time).append("\n");
                sb.append("  Môn: ").append(s.getEnrollment().getCourse().getCourseName()).append("\n");
                sb.append("  Phòng: ").append(nvl(s.getRoom())).append("\n");
                sb.append("  Giảng viên: ").append(nvl(s.getLecturer())).append("\n");
            });

        return sb.toString();
    }

    private String buildFailedCoursesContext(String studentCode, String userMessage) {
        // Lấy tất cả grades của sinh viên, lọc result ="Failed"
        List<Enrollment> allEnrollments = enrollmentRepository.findAllByStudentCode(studentCode);
        if (allEnrollments.isEmpty()) return "Không có dữ liệu môn học.\n";

        List<Long> allIds = allEnrollments.stream().map(Enrollment::getId).collect(Collectors.toList());

        // Query tất cả grades rồi lọc phía Java
        List<Grade> allGrades = gradeRepository.findAllByEnrollmentIds(allIds);

        List<Grade> failed = allGrades.stream()
                .filter(g -> g.getResult() != null &&
                        (g.getResult().equalsIgnoreCase("Failed")
                        || (g.getFinalScore10() != null && g.getFinalScore10() < 4.0f)))
                .collect(Collectors.toList());

        StringBuilder sb = new StringBuilder("=== CÁC MÔN KHÔNG ĐẠT ===\n");
        if (failed.isEmpty()) {
            sb.append("Không có môn nào không đạt.\n");
        } else {
            for (Grade g : failed) {
                Enrollment e = g.getEnrollment();
                sb.append("Môn: ").append(e.getCourse().getCourseName())
                  .append(" (").append(e.getCourse().getCourseCode()).append(")")
                  .append(" - HK").append(e.getSemester()).append(" ").append(e.getAcademicYear()).append("\n");
                sb.append("  Điểm tổng kết: ").append(g.getFinalScore10() != null ? g.getFinalScore10() : "Chưa có").append("/10\n");
                sb.append("  Kết quả: ").append(nvl(g.getResult())).append("\n");
            }
        }
        return sb.toString();
    }

    private String buildScheduleTodayContext(String studentCode, String userMessage) {
        // Lấy thứ trong tuần của ngày hôm nay
        java.time.DayOfWeek dow = java.time.LocalDate.now().getDayOfWeek();

        int todayCode = dow == java.time.DayOfWeek.SUNDAY ? 8 : dow.getValue() + 1;
        String todayName = DAY_NAMES.getOrDefault(todayCode, "Hôm nay");

        String[] semInfo = extractSemesterFromMessage(userMessage, studentCode);
        String academicYear = semInfo[0];
        String semester = semInfo[1];

        List<Enrollment> enrollments = enrollmentRepository.findByStudentAndSemester(studentCode, academicYear, semester);
        if (enrollments.isEmpty()) return "Không có dữ liệu lịch học cho học kỳ hiện tại.\n";

        List<Long> ids = enrollments.stream().map(Enrollment::getId).collect(Collectors.toList());
        List<Schedule> schedules = scheduleRepository.findByEnrollmentIds(ids);

        List<Schedule> todaySchedules = schedules.stream()
                .filter(s -> s.getDayOfWeek() != null && s.getDayOfWeek() == todayCode)
                .sorted(Comparator.comparingInt(Schedule::getPeriod))
                .collect(Collectors.toList());

        StringBuilder sb = new StringBuilder();
        sb.append("=== LỊCH HỌC HÔM NAY (").append(todayName).append(") ===\n");
        sb.append("Học kỳ ").append(semester).append(" - Năm học ").append(academicYear).append("\n");

        if (todaySchedules.isEmpty()) {
            sb.append("Hôm nay không có lịch học.\n");
        } else {
            for (Schedule s : todaySchedules) {
                String time = PERIOD_TIMES.getOrDefault(s.getPeriod(), "Ca " + s.getPeriod());
                sb.append("Ca ").append(s.getPeriod()).append(" (").append(time).append(")\n");
                sb.append("  Môn: ").append(s.getEnrollment().getCourse().getCourseName()).append("\n");
                sb.append("  Phòng: ").append(nvl(s.getRoom())).append("\n");
                sb.append("  Giảng viên: ").append(nvl(s.getLecturer())).append("\n");
            }
        }
        return sb.toString();
    }

    private String buildSemesterContext(String studentCode) {
        List<Object[]> rows = enrollmentRepository.findDistinctSemestersByStudent(studentCode);
        StringBuilder sb = new StringBuilder("=== DANH SÁCH HỌC KỲ ĐÃ HỌC ===\n");
        for (Object[] row : rows) {
            sb.append("Học kỳ ").append(row[0]).append(" - Năm học ").append(row[1]).append("\n");
        }
        return sb.toString();
    }

    // Extract semester
    private String[] extractSemesterFromMessage(String message, String studentCode) {
        String m = message.toLowerCase();
        String semester = null;
        String academicYear = null;

        // Detect semester number
        if (containsAny(m, "học kỳ 1", "hk1", "kỳ 1")) semester = "1";
        else if (containsAny(m, "học kỳ 2", "hk2", "kỳ 2")) semester = "2";
        else if (containsAny(m, "học kỳ 3", "hk3", "kỳ 3", "học kỳ hè", "kỳ hè")) semester = "3";

        // Pattern 1: YYYY-YYYY
        java.util.regex.Matcher fullYear = java.util.regex.Pattern
                .compile("(\\d{4})[-–](\\d{4})").matcher(message);
        if (fullYear.find()) {
            academicYear = fullYear.group(1) + "-" + fullYear.group(2);
        }

        // Pattern 2: năm đơn YYYY
        if (academicYear == null) {
            java.util.regex.Matcher singleYear = java.util.regex.Pattern
                    .compile("\\b(20\\d{2})\\b").matcher(message);
            if (singleYear.find()) {
                int year = Integer.parseInt(singleYear.group(1));
                if ("2".equals(semester) || "3".equals(semester)) {
                    academicYear = (year - 1) + "-" + year;
                } else {
                    academicYear = year + "-" + (year + 1);
                }
            }
        }

        // Fallback: lấy học kỳ mới nhất từ DB
        if (semester == null || academicYear == null) {
            List<Object[]> rows = enrollmentRepository.findDistinctSemestersByStudent(studentCode);
            if (!rows.isEmpty()) {
                Object[] latest = rows.get(0);
                if (semester == null) semester = (String) latest[0];
                if (academicYear == null) academicYear = (String) latest[1];
            } else {
                if (semester == null) semester = "1";
                if (academicYear == null) academicYear = "2024-2025";
            }
        }

        return new String[]{academicYear, semester};
    }

    // System prompt builder
    private String buildSystemPrompt(String dbContext) {
        return """
            Bạn là trợ lý AI của Trường Đại học Nông Lâm TP.HCM (NLU).
            Nhiệm vụ của bạn là hỗ trợ sinh viên tra cứu thông tin học tập và giải đáp thắc mắc liên quan đến trường.

            PHẠM VI TRẢ LỜI:
            - Thông tin cá nhân sinh viên (từ dữ liệu bên dưới)
            - Điểm số, kết quả học tập (từ dữ liệu bên dưới)
            - Lịch học, thời khóa biểu (từ dữ liệu bên dưới)
            - Thông tin về Trường Đại học Nông Lâm TP.HCM: địa chỉ, khoa, ngành, quy chế học vụ, học phí, học bổng, ký túc xá, thư viện, v.v.
            - Cách tính điểm: Điểm tổng kết = 40% điểm quá trình + 60% điểm thi. Thang điểm 10 và thang điểm 4 (A=3.6-4.0, B+=3.2-3.5, B=2.8-3.1, C+=2.4-2.7, C=2.0-2.3, D+=1.6-1.9, D=1.2-1.5, F=0-1.1).

            GIỚI HẠN:
            - Không trả lời các câu hỏi ngoài phạm vi học tập và thông tin trường NLU.
            - Nếu câu hỏi không liên quan, hãy lịch sự từ chối và nhắc lại phạm vi hỗ trợ.
            - Không bịa đặt thông tin không có trong dữ liệu được cung cấp.
            - Nếu không có dữ liệu, hãy thông báo rõ ràng.

            PHONG CÁCH:
            - Trả lời bằng tiếng Việt, thân thiện, rõ ràng, ngắn gọn.
            - Dùng danh sách hoặc bảng khi trình bày nhiều thông tin.

            """ + (dbContext.isBlank() ? "" : "DỮ LIỆU SINH VIÊN:\n" + dbContext);
    }

    // OpenAI API call
    private String callOpenAi(String systemPrompt, String userMessage) throws Exception {
        OkHttpClient client = new OkHttpClient.Builder()
                .connectTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
                .readTimeout(60, java.util.concurrent.TimeUnit.SECONDS)
                .build();

        ObjectMapper mapper = new ObjectMapper();

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", openAiModel);
        body.put("messages", List.of(
            Map.of("role", "system", "content", systemPrompt),
            Map.of("role", "user", "content", userMessage)
        ));
        body.put("temperature", 0.5);
        body.put("max_tokens", 1024);

        String jsonBody = mapper.writeValueAsString(body);

        Request request = new Request.Builder()
                .url(OPENAI_URL)
                .addHeader("Authorization", "Bearer " + openAiApiKey)
                .addHeader("Content-Type", "application/json")
                .post(RequestBody.create(jsonBody, MediaType.parse("application/json")))
                .build();

        try (Response response = client.newCall(request).execute()) {
            String responseBody = response.body() != null ? response.body().string() : "";
            if (!response.isSuccessful()) {
                log.error("OpenAI error {}: {}", response.code(), responseBody);
                throw new RuntimeException("OpenAI API lỗi: " + response.code());
            }
            JsonNode root = mapper.readTree(responseBody);
            return root.path("choices").get(0).path("message").path("content").asText();
        }
    }

    // Save log
    private void saveChatLog(String studentCode, String question, String answer, boolean flagged) {
        try {
            Student student = studentRepository.findByStudentCode(studentCode).orElse(null);
            ChatbotLog log = new ChatbotLog();
            log.setStudent(student);
            log.setQuestion(question);
            log.setAnswer(answer);
            log.setCreatedAt(LocalDateTime.now());
            log.setIsFlagged(flagged);
            chatbotLogRepository.save(log);
        } catch (Exception e) {
            log.error("Failed to save chatbot log: {}", e.getMessage());
        }
    }

    private String nvl(String val) {
        return val != null ? val : "Chưa cập nhật";
    }

    static class OutOfScopeException extends RuntimeException {
        OutOfScopeException(String message) { super(message); }
    }
}
