package com.example.nlu.service;

import com.example.nlu.dto.response.ChatbotLogResponse;
import com.example.nlu.entity.*;
import com.example.nlu.repo.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import okhttp3.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.*;
import java.time.format.DateTimeFormatter;
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
    private static final int MAX_TOOL_ROUNDS = 5;

    private static final Map<Integer, String> DAY_NAMES = Map.of(
        2, "Thứ Hai", 3, "Thứ Ba", 4, "Thứ Tư",
        5, "Thứ Năm", 6, "Thứ Sáu", 7, "Thứ Bảy", 8, "Chủ Nhật"
    );
    private static final Map<Integer, String> PERIOD_TIMES = Map.of(
        1, "07:00 - 09:15", 2, "09:30 - 11:45",
        3, "12:30 - 14:45", 4, "15:00 - 17:15"
    );

    // ==================== PUBLIC ENTRY POINT ====================

    public String chat(String studentCode, String userMessage) {
        String answer;
        boolean flagged = false;

        try {
            answer = runFunctionCallingLoop(studentCode, userMessage);
        } catch (Exception e) {
            log.error("Chatbot error for student {}: {}", studentCode, e.getMessage(), e);
            answer = "Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.";
        }

        saveChatLog(studentCode, userMessage, answer, flagged);
        return answer;
    }

    public List<ChatbotLogResponse> getHistory(String studentCode) {
        return chatbotLogRepository.findByStudentCodeOrderByCreatedAt(studentCode)
                .stream()
                .map(c -> ChatbotLogResponse.builder()
                        .id(c.getId())
                        .question(c.getQuestion())
                        .answer(c.getAnswer())
                        .createdAt(c.getCreatedAt() != null ? c.getCreatedAt().toString() : null)
                        .isFlagged(c.getIsFlagged())
                        .build())
                .toList();
    }

    // ==================== FUNCTION CALLING LOOP ====================

    /**
     * Agentic loop: gửi messages → LLM gọi tool → thực thi tool → gửi lại kết quả → lặp cho đến khi LLM trả lời text.
     */
    private String runFunctionCallingLoop(String studentCode, String userMessage) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        OkHttpClient client = buildHttpClient();

        // Khởi tạo messages
        List<Map<String, Object>> messages = new ArrayList<>();
        messages.add(Map.of("role", "system", "content", buildSystemPrompt(studentCode)));
        messages.add(Map.of("role", "user", "content", userMessage));

        // Định nghĩa tools
        JsonNode tools = buildToolDefinitions(mapper);

        for (int round = 0; round < MAX_TOOL_ROUNDS; round++) {
            String responseBody = callOpenAiRaw(client, mapper, messages, tools);
            JsonNode root = mapper.readTree(responseBody);
            JsonNode choice = root.path("choices").get(0);
            JsonNode message = choice.path("message");
            String finishReason = choice.path("finish_reason").asText();

            // Thêm assistant message vào history
            messages.add(jsonNodeToMap(message, mapper));

            if ("tool_calls".equals(finishReason)) {
                // Thực thi từng tool call và thêm kết quả vào messages
                JsonNode toolCalls = message.path("tool_calls");
                for (JsonNode tc : toolCalls) {
                    String toolCallId = tc.path("id").asText();
                    String funcName = tc.path("function").path("name").asText();
                    String argsJson = tc.path("function").path("arguments").asText();
                    JsonNode args = mapper.readTree(argsJson);

                    log.info("Tool call [{}] {} with args: {}", toolCallId, funcName, argsJson);
                    String toolResult = dispatchTool(studentCode, funcName, args);
                    log.info("Tool result [{}]: {}...", toolCallId, toolResult.substring(0, Math.min(200, toolResult.length())));

                    messages.add(Map.of(
                        "role", "tool",
                        "tool_call_id", toolCallId,
                        "content", toolResult
                    ));
                }
            } else {
                // LLM đã trả lời text
                return message.path("content").asText("Xin lỗi, tôi không thể trả lời câu hỏi này.");
            }
        }

        return "Xin lỗi, không thể xử lý yêu cầu của bạn lúc này.";
    }

    // ==================== TOOL DISPATCH ====================

    private String dispatchTool(String studentCode, String funcName, JsonNode args) {
        try {
            return switch (funcName) {
                case "get_student_info"     -> toolGetStudentInfo(studentCode);
                case "get_grades"           -> toolGetGrades(studentCode,
                                                    args.path("academic_year").asText(null),
                                                    args.path("semester").asText(null));
                case "get_gpa_summary"      -> toolGetGpaSummary(studentCode,
                                                    args.path("academic_year").asText(null),
                                                    args.path("semester").asText(null));
                case "get_schedule"         -> toolGetSchedule(studentCode,
                                                    args.path("academic_year").asText(null),
                                                    args.path("semester").asText(null));
                case "get_schedule_by_date" -> toolGetScheduleByDate(studentCode,
                                                    args.path("date").asText(null));
                case "get_failed_courses"   -> toolGetFailedCourses(studentCode);
                case "get_all_semesters"    -> toolGetAllSemesters(studentCode);
                case "get_cumulative_gpa"   -> toolGetCumulativeGpa(studentCode);
                default -> "Không tìm thấy function: " + funcName;
            };
        } catch (Exception e) {
            log.error("Tool {} error: {}", funcName, e.getMessage(), e);
            return "Lỗi khi lấy dữ liệu: " + e.getMessage();
        }
    }

    // ==================== TOOL IMPLEMENTATIONS ====================

    private String toolGetStudentInfo(String studentCode) {
        Student s = studentRepository.findByStudentCode(studentCode).orElse(null);
        if (s == null) return "Không tìm thấy sinh viên.";

        Optional<StudentProgram> spOpt = studentProgramRepository.findFirstByStudent_StudentCode(studentCode);
        StringBuilder sb = new StringBuilder();
        sb.append("MSSV: ").append(s.getStudentCode()).append("\n");
        sb.append("Họ tên: ").append(nvl(s.getFullName())).append("\n");
        sb.append("Ngày sinh: ").append(s.getDateOfBirth() != null ? s.getDateOfBirth().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) : "Chưa cập nhật").append("\n");
        sb.append("Giới tính: ").append(nvl(s.getGender())).append("\n");
        sb.append("SĐT: ").append(nvl(s.getPhone())).append("\n");
        sb.append("CCCD: ").append(nvl(s.getCccd())).append("\n");
        sb.append("Dân tộc: ").append(nvl(s.getEthnicity())).append("\n");
        sb.append("Tôn giáo: ").append(nvl(s.getReligion())).append("\n");
        sb.append("Quốc tịch: ").append(nvl(s.getNationality())).append("\n");
        sb.append("Nơi sinh: ").append(nvl(s.getPlaceOfBirth())).append("\n");
        sb.append("Trạng thái: ").append(s.getStatus() != null ? s.getStatus().name() : "—").append("\n");
        spOpt.ifPresent(sp -> {
            sb.append("Khoa: ").append(nvl(sp.getProgram().getFaculty())).append("\n");
            sb.append("Ngành: ").append(nvl(sp.getProgram().getMajor())).append("\n");
            sb.append("Chuyên ngành: ").append(nvl(sp.getProgram().getSpecialization())).append("\n");
            sb.append("Lớp: ").append(nvl(sp.getClassName())).append("\n");
            sb.append("Loại hình: ").append(nvl(sp.getProgram().getEducationType())).append("\n");
            sb.append("Khóa: ").append(sp.getStartYear()).append(" - ").append(sp.getEndYear()).append("\n");
        });
        return sb.toString();
    }

    private String toolGetGrades(String studentCode, String academicYear, String semester) {
        String[] resolved = resolveSemester(studentCode, academicYear, semester);
        String ay = resolved[0], sem = resolved[1];

        List<Enrollment> enrollments = enrollmentRepository.findByStudentAndSemester(studentCode, ay, sem)
                .stream()
                .filter(e -> !Boolean.TRUE.equals(e.getSection().getIsLab()))
                .collect(Collectors.toList());
        if (enrollments.isEmpty()) return "Không có dữ liệu đăng ký môn học kỳ " + sem + " năm " + ay + ".";

        List<Grade> grades = gradeRepository.findByStudentAndSemester(studentCode, ay, sem);
        Map<Long, Grade> gradeMap = grades.stream()
                .collect(Collectors.toMap(g -> g.getEnrollment().getId(), g -> g, (a, b) -> a));

        StringBuilder sb = new StringBuilder();
        sb.append("Bảng điểm HK").append(sem).append(" năm học ").append(ay).append(":\n");
        for (Enrollment e : enrollments) {
            Course c = e.getSection().getCourse();
            Grade g = gradeMap.get(e.getId());
            sb.append("- ").append(c.getCourseName()).append(" (").append(c.getCourseCode()).append(") - ").append(c.getCredits()).append(" TC\n");
            if (g != null) {
                sb.append("  ĐQT: ").append(g.getProcessScore() != null ? g.getProcessScore() : "Chưa có");
                sb.append(" | ĐThi: ").append(g.getExamScore() != null ? g.getExamScore() : "Chưa có");
                sb.append(" | ĐTK/10: ").append(g.getFinalScore10() != null ? g.getFinalScore10() : "Chưa có");
                sb.append(" | ĐTK/4: ").append(g.getFinalScore4() != null ? g.getFinalScore4() : "Chưa có");
                sb.append(" | ").append(nvl(g.getResult())).append("\n");
            } else {
                sb.append("  Chưa có điểm\n");
            }
        }
        return sb.toString();
    }

    private String toolGetGpaSummary(String studentCode, String academicYear, String semester) {
        String[] resolved = resolveSemester(studentCode, academicYear, semester);
        String ay = resolved[0], sem = resolved[1];

        Optional<SemesterSummary> ssOpt = semesterSummaryRepository.findByStudentAndSemester(studentCode, ay, sem);
        StringBuilder sb = new StringBuilder();
        sb.append("Kết quả HK").append(sem).append(" năm học ").append(ay).append(":\n");
        ssOpt.ifPresentOrElse(ss -> {
            sb.append("GPA kỳ/10: ").append(ss.getGpa10() != null ? ss.getGpa10() : "Chưa có").append("\n");
            sb.append("GPA kỳ/4: ").append(ss.getGpa4() != null ? ss.getGpa4() : "Chưa có").append("\n");
            sb.append("GPA tích lũy/10: ").append(ss.getCumulativeGpa10() != null ? ss.getCumulativeGpa10() : "Chưa có").append("\n");
            sb.append("GPA tích lũy/4: ").append(ss.getCumulativeGpa4() != null ? ss.getCumulativeGpa4() : "Chưa có").append("\n");
            sb.append("TC học kỳ: ").append(ss.getSemesterCredits() != null ? ss.getSemesterCredits() : "Chưa có").append("\n");
            sb.append("TC tích lũy: ").append(ss.getCumulativeCredits() != null ? ss.getCumulativeCredits() : "Chưa có").append("\n");
        }, () -> sb.append("Chưa có dữ liệu tổng kết học kỳ này.\n"));
        return sb.toString();
    }

    private String toolGetCumulativeGpa(String studentCode) {
        List<SemesterSummary> summaries = semesterSummaryRepository.findAllByStudentCode(studentCode);
        if (summaries.isEmpty()) return "Chưa có dữ liệu GPA tích lũy.";

        // Lấy học kỳ mới nhất (có cumulative GPA)
        Optional<SemesterSummary> latest = summaries.stream()
                .filter(ss -> ss.getCumulativeGpa4() != null)
                .max(Comparator.comparing(ss -> ss.getAcademicYear() + "|" + ss.getSemester()));

        StringBuilder sb = new StringBuilder("GPA tích lũy toàn khóa:\n");
        latest.ifPresentOrElse(ss -> {
            sb.append("GPA tích lũy/4: ").append(ss.getCumulativeGpa4()).append("\n");
            sb.append("GPA tích lũy/10: ").append(ss.getCumulativeGpa10() != null ? ss.getCumulativeGpa10() : "N/A").append("\n");
            sb.append("Tổng TC tích lũy: ").append(ss.getCumulativeCredits() != null ? ss.getCumulativeCredits() : "N/A").append("\n");
            sb.append("(Tính đến HK").append(ss.getSemester()).append(" năm ").append(ss.getAcademicYear()).append(")\n");
        }, () -> sb.append("Chưa có dữ liệu.\n"));
        return sb.toString();
    }

    private String toolGetSchedule(String studentCode, String academicYear, String semester) {
        String[] resolved = resolveSemester(studentCode, academicYear, semester);
        String ay = resolved[0], sem = resolved[1];

        List<Enrollment> enrollments = enrollmentRepository.findByStudentAndSemester(studentCode, ay, sem);
        if (enrollments.isEmpty()) return "Không có lịch học cho HK" + sem + " năm " + ay + ".";

        List<Long> ids = enrollments.stream().map(e -> e.getSection().getId()).collect(Collectors.toList());
        List<Schedule> schedules = scheduleRepository.findBySectionIds(ids);

        StringBuilder sb = new StringBuilder();
        sb.append("TKB HK").append(sem).append(" năm học ").append(ay).append(":\n");
        schedules.stream()
            .sorted(Comparator.comparingInt(Schedule::getDayOfWeek).thenComparingInt(Schedule::getPeriod))
            .forEach(s -> {
                String day = DAY_NAMES.getOrDefault(s.getDayOfWeek(), "Thứ " + s.getDayOfWeek());
                String time = PERIOD_TIMES.getOrDefault(s.getPeriod(), "Ca " + s.getPeriod());
                sb.append("- ").append(day).append(", Ca ").append(s.getPeriod()).append(" (").append(time).append(")\n");
                sb.append("  Môn: ").append(s.getSection().getCourse().getCourseName()).append("\n");
                sb.append("  Phòng: ").append(nvl(s.getRoom()))
                  .append(" | GV: ").append(nvl(s.getLecturer())).append("\n");
            });
        return sb.toString();
    }

    private String toolGetScheduleByDate(String studentCode, String dateStr) {
        final LocalDate date;
        LocalDate parsed;
        try {
            parsed = (dateStr == null || dateStr.isBlank())
                    ? LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"))
                    : LocalDate.parse(dateStr, DateTimeFormatter.ISO_LOCAL_DATE);
        } catch (Exception e) {
            parsed = LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"));
        }
        date = parsed;

        DayOfWeek dow = date.getDayOfWeek();
        final int dayCode = dow == DayOfWeek.SUNDAY ? 8 : dow.getValue() + 1;
        String dayName = DAY_NAMES.getOrDefault(dayCode, "Ngày " + date);

        // Lấy học kỳ đang active (dựa trên ngày)
        String[] semInfo = resolveSemesterByDate(studentCode, date);
        String ay = semInfo[0], sem = semInfo[1];

        List<Enrollment> enrollments = enrollmentRepository.findByStudentAndSemester(studentCode, ay, sem);
        if (enrollments.isEmpty()) return "Không có dữ liệu lịch học cho ngày " + date.format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) + ".";

        // Chỉ lấy sections còn active tại ngày được hỏi (startDate <= date <= endDate)
        List<Long> ids = enrollments.stream()
                .filter(e -> {
                    LocalDate start = e.getSection().getStartDate();
                    LocalDate end = e.getSection().getEndDate();
                    if (start == null || end == null) return true; // không có date thì giữ lại
                    return !date.isBefore(start) && !date.isAfter(end);
                })
                .map(e -> e.getSection().getId())
                .collect(Collectors.toList());

        if (ids.isEmpty()) return "Không có lịch học vào ngày " + date.format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) + ".";

        List<Schedule> schedules = scheduleRepository.findBySectionIds(ids);

        List<Schedule> daySchedules = schedules.stream()
                .filter(s -> s.getDayOfWeek() != null && s.getDayOfWeek() == dayCode)
                .sorted(Comparator.comparingInt(Schedule::getPeriod))
                .collect(Collectors.toList());

        StringBuilder sb = new StringBuilder();
        sb.append("Lịch học ngày ").append(date.format(DateTimeFormatter.ofPattern("dd/MM/yyyy")))
          .append(" (").append(dayName).append(") - HK").append(sem).append(" năm ").append(ay).append(":\n");

        if (daySchedules.isEmpty()) {
            sb.append("Không có lịch học vào ngày này.");
        } else {
            for (Schedule s : daySchedules) {
                String time = PERIOD_TIMES.getOrDefault(s.getPeriod(), "Ca " + s.getPeriod());
                sb.append("- Ca ").append(s.getPeriod()).append(" (").append(time).append(")\n");
                sb.append("  Môn: ").append(s.getSection().getCourse().getCourseName()).append("\n");
                sb.append("  Phòng: ").append(nvl(s.getRoom()))
                  .append(" | GV: ").append(nvl(s.getLecturer())).append("\n");
            }
        }
        return sb.toString();
    }

    private String toolGetFailedCourses(String studentCode) {
        List<Enrollment> allEnrollments = enrollmentRepository.findAllByStudentCode(studentCode);
        if (allEnrollments.isEmpty()) return "Không có dữ liệu môn học.";

        List<Long> enrollmentIds = allEnrollments.stream().map(Enrollment::getId).collect(Collectors.toList());
        List<Grade> allGrades = gradeRepository.findAllByEnrollmentIds(enrollmentIds);

        List<Grade> failed = allGrades.stream()
                .filter(g -> g.getFinalScore10() != null && g.getFinalScore10() < 4.0f
                        || (g.getResult() != null && g.getResult().equalsIgnoreCase("Failed")))
                .collect(Collectors.toList());

        if (failed.isEmpty()) return "Không có môn nào không đạt.";

        StringBuilder sb = new StringBuilder("Các môn không đạt:\n");
        for (Grade g : failed) {
            Section sec = g.getEnrollment().getSection();
            sb.append("- ").append(sec.getCourse().getCourseName())
              .append(" (").append(sec.getCourse().getCourseCode()).append(")")
              .append(" HK").append(sec.getSemester()).append(" ").append(sec.getAcademicYear()).append("\n");
            sb.append("  ĐTK/10: ").append(g.getFinalScore10() != null ? g.getFinalScore10() : "N/A")
              .append(" | KQ: ").append(nvl(g.getResult())).append("\n");
        }
        return sb.toString();
    }

    private String toolGetAllSemesters(String studentCode) {
        List<Object[]> rows = enrollmentRepository.findDistinctSemestersByStudent(studentCode);
        if (rows.isEmpty()) return "Chưa có dữ liệu học kỳ.";

        StringBuilder sb = new StringBuilder("Danh sách học kỳ đã học:\n");
        for (Object[] row : rows) {
            sb.append("- HK").append(row[0]).append(" năm học ").append(row[1]).append("\n");
        }
        return sb.toString();
    }

    // ==================== OPENAI FUNCTION DEFINITIONS ====================

    private JsonNode buildToolDefinitions(ObjectMapper mapper) {
        ArrayNode tools = mapper.createArrayNode();

        tools.add(buildTool(mapper, "get_student_info",
            "Lấy thông tin cá nhân của sinh viên: họ tên, ngày sinh, MSSV, lớp, ngành, khoa, v.v.",
            mapper.createObjectNode()));

        ObjectNode gradesProps = mapper.createObjectNode();
        gradesProps.set("academic_year", strProp(mapper, "Năm học, format YYYY-YYYY, ví dụ 2024-2025. Nếu không có thì bỏ qua."));
        gradesProps.set("semester", strProp(mapper, "Học kỳ: '1', '2', hoặc '3'. Nếu không có thì bỏ qua."));
        tools.add(buildTool(mapper, "get_grades",
            "Lấy bảng điểm (điểm quá trình, điểm thi, điểm tổng kết) của sinh viên theo học kỳ. Nếu không chỉ định học kỳ thì lấy học kỳ gần nhất.",
            gradesProps));

        ObjectNode gpaProps = mapper.createObjectNode();
        gpaProps.set("academic_year", strProp(mapper, "Năm học, format YYYY-YYYY. Nếu không có thì bỏ qua."));
        gpaProps.set("semester", strProp(mapper, "Học kỳ: '1', '2', hoặc '3'. Nếu không có thì bỏ qua."));
        tools.add(buildTool(mapper, "get_gpa_summary",
            "Lấy GPA học kỳ và GPA tích lũy của sinh viên. Dùng khi hỏi về điểm trung bình, xếp loại học lực, tín chỉ tích lũy.",
            gpaProps));

        tools.add(buildTool(mapper, "get_cumulative_gpa",
            "Lấy GPA tích lũy toàn khóa (mới nhất) và tổng tín chỉ tích lũy.",
            mapper.createObjectNode()));

        ObjectNode schedProps = mapper.createObjectNode();
        schedProps.set("academic_year", strProp(mapper, "Năm học, format YYYY-YYYY. Nếu không có thì bỏ qua."));
        schedProps.set("semester", strProp(mapper, "Học kỳ: '1', '2', hoặc '3'. Nếu không có thì bỏ qua."));
        tools.add(buildTool(mapper, "get_schedule",
            "Lấy thời khóa biểu (TKB) theo học kỳ: môn học, phòng, giảng viên, thứ, tiết. Nếu không chỉ định học kỳ thì lấy học kỳ hiện tại.",
            schedProps));

        ObjectNode dateProps = mapper.createObjectNode();
        dateProps.set("date", strProp(mapper, "Ngày cụ thể format YYYY-MM-DD. Ví dụ: hôm nay=" + LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")) + ", ngày mai=" + LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(1) + ", hôm qua=" + LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).minusDays(1)));
        tools.add(buildTool(mapper, "get_schedule_by_date",
            "Lấy lịch học của một ngày cụ thể (hôm nay, ngày mai, hôm qua, hoặc ngày bất kỳ). Truyền date theo format YYYY-MM-DD.",
            dateProps));

        tools.add(buildTool(mapper, "get_failed_courses",
            "Lấy danh sách các môn học không đạt (rớt môn, điểm F, môn phải học lại) của sinh viên qua tất cả các học kỳ.",
            mapper.createObjectNode()));

        tools.add(buildTool(mapper, "get_all_semesters",
            "Lấy danh sách tất cả các học kỳ mà sinh viên đã đăng ký học.",
            mapper.createObjectNode()));

        return tools;
    }

    private ObjectNode buildTool(ObjectMapper mapper, String name, String description, ObjectNode properties) {
        ObjectNode tool = mapper.createObjectNode();
        tool.put("type", "function");
        ObjectNode func = mapper.createObjectNode();
        func.put("name", name);
        func.put("description", description);
        ObjectNode params = mapper.createObjectNode();
        params.put("type", "object");
        params.set("properties", properties);
        func.set("parameters", params);
        tool.set("function", func);
        return tool;
    }

    private ObjectNode strProp(ObjectMapper mapper, String description) {
        ObjectNode prop = mapper.createObjectNode();
        prop.put("type", "string");
        prop.put("description", description);
        return prop;
    }

    // ==================== SYSTEM PROMPT ====================

    private String buildSystemPrompt(String studentCode) {
        LocalDate today = LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"));
        String todayStr = today.format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
        String todayIso = today.format(DateTimeFormatter.ISO_LOCAL_DATE);
        DayOfWeek dow = today.getDayOfWeek();
        int dayCode = dow == DayOfWeek.SUNDAY ? 8 : dow.getValue() + 1;
        String todayName = DAY_NAMES.getOrDefault(dayCode, "");

        return """
            Bạn là trợ lý AI chính thức của Trường Đại học Nông Lâm TP.HCM (NLU - Nông Lâm University).
            Bạn đang hỗ trợ sinh viên có MSSV: %s
            Ngày hôm nay: %s (%s) - ISO: %s

            PHẠM VI TRẢ LỜI:
            1. Thông tin cá nhân của chính sinh viên này (dùng tool get_student_info)
            2. Điểm số, GPA, xếp loại học lực của sinh viên này (dùng get_grades, get_gpa_summary, get_cumulative_gpa)
            3. Lịch học, thời khóa biểu (dùng get_schedule, get_schedule_by_date)
            4. Môn học lại, môn rớt (dùng get_failed_courses)
            5. Các học kỳ đã học (dùng get_all_semesters)
            6. Thông tin chung về Trường Đại học Nông Lâm TP.HCM:
               - Địa chỉ: Khu phố 6, P. Linh Trung, TP. Thủ Đức, TP.HCM
               - Website: www.hcmuaf.edu.vn
               - Thành lập: 1955
               - Các khoa: Nông học, Chăn nuôi Thú y, Thủy sản, Lâm nghiệp, Cơ khí Công nghệ, Công nghệ Thực phẩm, Kinh tế, Môi trường, Công nghệ Thông tin, v.v.
            7. Quy chế và cách tính điểm:
               - Điểm tổng kết = 50%% điểm quá trình + 50%% điểm thi cuối kỳ (hoặc theo quy định môn học)
               - Thang điểm 10: ≥5.0 là đạt; <5.0 là không đạt (F)
               - Thang điểm 4: A(8.5-10), B+(7.0-8.4), B(6.0-6.9), C+(5.5-5.9), C(5.0-5.4), D+(4.0-4.9), D(3.5-3.9), F(<3.5)
               - Điểm tích lũy trung bình = tổng (điểm×tín chỉ) / tổng tín chỉ (thang 4)
               - Xếp loại: Xuất sắc ≥3.6, Giỏi 3.2-3.59, Khá 2.5-3.19, Trung bình khá 2.0-2.49, Trung bình 1.0-1.99, Yếu <1.0

            GIỚI HẠN TUYỆT ĐỐI:
            - CHỈ trả lời thông tin của sinh viên %s. Không được truy cập hay tiết lộ thông tin của sinh viên khác.
            - Không trả lời các câu hỏi ngoài phạm vi học tập và thông tin trường NLU.
            - Không bịa đặt thông tin; nếu không có dữ liệu từ tool, hãy nói rõ là chưa có dữ liệu.
            - Từ chối lịch sự nếu câu hỏi không liên quan đến học tập hoặc trường NLU.

            CÁCH DÙNG TOOL:
            - Hãy chủ động gọi tool để lấy dữ liệu khi cần, đừng đoán mò.
            - Có thể gọi nhiều tool cùng lúc nếu cần thiết.
            - Với câu hỏi về ngày cụ thể (hôm nay, ngày mai, hôm qua), hãy tính date đúng và truyền vào get_schedule_by_date.
            - Nếu user không chỉ định học kỳ, gọi tool mà không truyền tham số (hệ thống sẽ tự lấy học kỳ gần nhất).

            PHONG CÁCH:
            - Trả lời bằng tiếng Việt, thân thiện, rõ ràng, súc tích.
            - Format câu trả tự nhiên, dễ đọc.
            - Dùng danh sách khi có nhiều mục.
            """.formatted(studentCode, todayStr, todayName, todayIso, studentCode);
    }

    // ==================== HELPERS ====================

    /**
     * Resolve học kỳ: nếu cả hai đều null/blank thì lấy học kỳ mới nhất từ DB.
     */
    private String[] resolveSemester(String studentCode, String academicYear, String semester) {
        boolean needYear = academicYear == null || academicYear.isBlank();
        boolean needSem = semester == null || semester.isBlank();

        if (!needYear && !needSem) return new String[]{academicYear, semester};

        List<Object[]> rows = enrollmentRepository.findDistinctSemestersByStudent(studentCode);
        if (!rows.isEmpty()) {
            Object[] latest = rows.get(0);
            return new String[]{
                needYear ? (String) latest[1] : academicYear,
                needSem  ? (String) latest[0] : semester
            };
        }
        return new String[]{academicYear != null ? academicYear : "2024-2025", semester != null ? semester : "1"};
    }

    /**
     * Resolve học kỳ dựa trên ngày: tìm section nào có startDate <= date <= endDate.
     * Fallback về học kỳ mới nhất nếu không tìm được.
     */
    private String[] resolveSemesterByDate(String studentCode, LocalDate date) {
        List<Enrollment> all = enrollmentRepository.findAllByStudentCode(studentCode);
        Optional<Enrollment> match = all.stream()
                .filter(e -> {
                    LocalDate start = e.getSection().getStartDate();
                    LocalDate end = e.getSection().getEndDate();
                    return start != null && end != null && !date.isBefore(start) && !date.isAfter(end);
                })
                .findFirst();

        if (match.isPresent()) {
            Section sec = match.get().getSection();
            return new String[]{sec.getAcademicYear(), sec.getSemester()};
        }

        // Fallback: học kỳ mới nhất
        return resolveSemester(studentCode, null, null);
    }

    private String callOpenAiRaw(OkHttpClient client, ObjectMapper mapper,
                                  List<Map<String, Object>> messages, JsonNode tools) throws Exception {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", openAiModel);
        body.put("messages", messages);
        body.put("tools", tools);
        body.put("tool_choice", "auto");
        body.put("temperature", 0.3);
        body.put("max_tokens", 1500);

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
                throw new RuntimeException("OpenAI API lỗi " + response.code());
            }
            return responseBody;
        }
    }

    private OkHttpClient buildHttpClient() {
        return new OkHttpClient.Builder()
                .connectTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
                .readTimeout(90, java.util.concurrent.TimeUnit.SECONDS)
                .build();
    }

    /**
     * Convert JsonNode (OpenAI assistant message) thành Map để thêm vào messages list.
     * Cần giữ nguyên cấu trúc tool_calls nếu có.
     */
    @SuppressWarnings("unchecked")
    private Map<String, Object> jsonNodeToMap(JsonNode node, ObjectMapper mapper) throws Exception {
        return mapper.convertValue(node, Map.class);
    }

    private void saveChatLog(String studentCode, String question, String answer, boolean flagged) {
        try {
            Student student = studentRepository.findByStudentCode(studentCode).orElse(null);
            ChatbotLog chatLog = new ChatbotLog();
            chatLog.setStudent(student);
            chatLog.setQuestion(question);
            chatLog.setAnswer(answer);
            chatLog.setCreatedAt(LocalDateTime.now());
            chatLog.setIsFlagged(flagged);
            chatbotLogRepository.save(chatLog);
        } catch (Exception e) {
            log.error("Failed to save chatbot log: {}", e.getMessage());
        }
    }

    private String nvl(String val) {
        return val != null ? val : "Chưa cập nhật";
    }
}
