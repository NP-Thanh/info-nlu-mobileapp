package com.example.nlu.service;

import com.example.nlu.dto.request.CreateScheduleRequest;
import com.example.nlu.dto.request.CreateSectionRequest;
import com.example.nlu.dto.request.CreateSectionScheduleRequest;
import com.example.nlu.dto.request.UpdateScheduleAdminRequest;
import com.example.nlu.dto.response.AdminScheduleDetailResponse;
import com.example.nlu.dto.response.AdminScheduleListResponse;
import com.example.nlu.dto.response.AdminSectionDetailResponse;
import com.example.nlu.dto.response.AdminSectionListResponse;
import com.example.nlu.dto.response.SectionScheduleResponse;
import com.example.nlu.dto.response.StudentInScheduleResponse;
import com.example.nlu.entity.*;
import com.example.nlu.repo.*;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminScheduleService {

    private final ScheduleRepository scheduleRepository;
    private final SectionRepository sectionRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final CourseRepository courseRepository;
    private final StudentRepository studentRepository;
    private final ScheduleService scheduleService;

    private static final Map<Integer, String[]> PERIOD_TIMES = Map.of(
        1, new String[]{"07:00", "09:15"},
        2, new String[]{"09:30", "11:45"},
        3, new String[]{"12:30", "14:45"},
        4, new String[]{"15:00", "17:15"}
    );

    // ── List / Filter ────────────────────────────────────────────────────────

    public List<AdminScheduleListResponse> getSchedules(String keyword, String semester, String academicYear) {
        List<Schedule> all = scheduleRepository.findAllActiveWithSection();

        if (keyword != null && !keyword.isBlank()) {
            String q = keyword.trim().toLowerCase();
            all = all.stream().filter(s -> {
                String name = s.getSection().getCourse().getCourseName().toLowerCase();
                String code = s.getSection().getCourse().getCourseCode().toLowerCase();
                return name.contains(q) || code.contains(q);
            }).collect(Collectors.toList());
        }
        if (semester != null && !semester.isBlank()) {
            all = all.stream()
                .filter(s -> semester.equals(s.getSection().getSemester()))
                .collect(Collectors.toList());
        }
        if (academicYear != null && !academicYear.isBlank()) {
            all = all.stream()
                .filter(s -> academicYear.equals(s.getSection().getAcademicYear()))
                .collect(Collectors.toList());
        }

        return all.stream().map(s -> toListResponse(s,
                enrollmentRepository.countBySection_Id(s.getSection().getId())))
                .collect(Collectors.toList());
    }

    public List<String> getDistinctAcademicYears() {
        return scheduleRepository.findDistinctAcademicYears();
    }

    // ── Detail ───────────────────────────────────────────────────────────────

    public AdminScheduleDetailResponse getScheduleDetail(Long scheduleId) {
        Schedule s = scheduleRepository.findByIdWithDetails(scheduleId)
            .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lịch học"));
        List<StudentInScheduleResponse> students = buildStudentList(s.getSection().getId());
        return toDetailResponse(s, students);
    }

    // ── Create ───────────────────────────────────────────────────────────────

    @Transactional
    public AdminScheduleDetailResponse createSchedule(CreateScheduleRequest req) {
        validateScheduleFields(req.getCourseId(), req.getSemester(), req.getAcademicYear(),
                req.getDayOfWeek(), req.getPeriod());

        Course course = courseRepository.findById(req.getCourseId())
            .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy môn học"));

        boolean dupSchedule = scheduleRepository.existsDuplicateSchedule(
            req.getCourseId(), req.getSemester(), req.getAcademicYear(),
            req.getDayOfWeek(), req.getPeriod(), req.getRoom(), null);
        if (dupSchedule) {
            throw new IllegalArgumentException(
                "Đã tồn tại lịch học trùng (cùng môn, học kỳ, năm học, ngày, ca, phòng)");
        }

        if (req.getLecturer() != null && !req.getLecturer().isBlank()) {
            boolean lecturerConflict = scheduleRepository.existsLecturerConflict(
                req.getLecturer(), req.getSemester(), req.getAcademicYear(),
                req.getDayOfWeek(), req.getPeriod(), null);
            if (lecturerConflict) {
                throw new IllegalArgumentException(
                    "Giảng viên \"" + req.getLecturer() + "\" đã có lịch dạy môn khác trong ca này");
            }
        }

        // Tìm hoặc tạo section cho course + semester + year + group + team
        Boolean isLab = Boolean.TRUE.equals(req.getIsLab());
        Integer groupNumber = req.getGroupNumber() != null ? req.getGroupNumber() : 1;
        Integer teamNumber = req.getTeamNumber() != null ? req.getTeamNumber() : 1;
        Section section = sectionRepository
            .findByCourseAndSemesterAndYearAndGroup(req.getCourseId(), req.getSemester(), req.getAcademicYear(), groupNumber, teamNumber)
            .stream().findFirst().orElseGet(() -> {
                Section sec = new Section();
                sec.setCourse(course);
                sec.setSemester(req.getSemester());
                sec.setAcademicYear(req.getAcademicYear());
                sec.setStartDate(req.getStartDate());
                sec.setEndDate(req.getEndDate());
                sec.setGroupNumber(groupNumber);
                sec.setTeamNumber(teamNumber);
                return sectionRepository.save(sec);
            });

        // Kiểm tra conflict lịch học cho sinh viên đã đăng ký section này
        List<Enrollment> enrollments = enrollmentRepository.findAllBySection_Id(section.getId());
        for (Enrollment e : enrollments) {
            List<Enrollment> conflicts = enrollmentRepository.findStudentConflicts(
                    e.getStudent().getId(), req.getSemester(), req.getAcademicYear(),
                    req.getDayOfWeek(), req.getPeriod(), section.getId());
            if (!conflicts.isEmpty()) {
                throw new IllegalArgumentException(
                        "Sinh viên " + e.getStudent().getStudentCode() + " bị trùng ca " + req.getPeriod() +
                        " thứ " + req.getDayOfWeek() + " với môn khác");
            }
        }

        Schedule schedule = new Schedule();
        schedule.setSection(section);
        schedule.setRoom(req.getRoom());
        schedule.setLecturer(req.getLecturer());
        schedule.setDayOfWeek(req.getDayOfWeek());
        schedule.setPeriod(req.getPeriod());
        schedule.setIsLab(isLab);
        schedule.setIsDeleted(false);
        scheduleRepository.save(schedule);

        return toDetailResponse(schedule, buildStudentList(section.getId()));
    }

    // ── Update ───────────────────────────────────────────────────────────────

    @Transactional
    public AdminScheduleDetailResponse updateSchedule(Long scheduleId, UpdateScheduleAdminRequest req) {
        Schedule schedule = scheduleRepository.findByIdWithDetails(scheduleId)
            .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lịch học"));

        if (req.getRoom() != null) schedule.setRoom(req.getRoom());
        if (req.getLecturer() != null) schedule.setLecturer(req.getLecturer());

        int newDay = req.getDayOfWeek() != null ? req.getDayOfWeek() : schedule.getDayOfWeek();
        int newPeriod = req.getPeriod() != null ? req.getPeriod() : schedule.getPeriod();

        if (newDay < 2 || newDay > 8)
            throw new IllegalArgumentException("Thứ trong tuần không hợp lệ (2-8)");
        if (newPeriod < 1 || newPeriod > 4)
            throw new IllegalArgumentException("Ca học không hợp lệ (1-4)");

        Section section = schedule.getSection();
        String semester = section.getSemester();
        String academicYear = section.getAcademicYear();

        boolean dupSchedule = scheduleRepository.existsDuplicateSchedule(
            section.getCourse().getId(), semester, academicYear,
            newDay, newPeriod, req.getRoom() != null ? req.getRoom() : schedule.getRoom(), scheduleId);
        if (dupSchedule) {
            throw new IllegalArgumentException("Đã tồn tại lịch học trùng (cùng môn, học kỳ, năm học, ngày, ca, phòng)");
        }

        String newLecturer = req.getLecturer() != null ? req.getLecturer() : schedule.getLecturer();
        if (newLecturer != null && !newLecturer.isBlank()) {
            boolean lecturerConflict = scheduleRepository.existsLecturerConflict(
                newLecturer, semester, academicYear, newDay, newPeriod, scheduleId);
            if (lecturerConflict) {
                throw new IllegalArgumentException(
                    "Giảng viên \"" + newLecturer + "\" đã có lịch dạy môn khác trong ca này");
            }
        }

        // Kiểm tra conflict lịch học cho sinh viên đang đăng ký học phần này
        List<Enrollment> enrollments = enrollmentRepository.findAllBySection_Id(section.getId());
        for (Enrollment e : enrollments) {
            List<Enrollment> conflicts = enrollmentRepository.findStudentConflicts(
                    e.getStudent().getId(), semester, academicYear,
                    newDay, newPeriod, section.getId());
            if (!conflicts.isEmpty()) {
                throw new IllegalArgumentException(
                        "Sinh viên " + e.getStudent().getStudentCode() + " bị trùng ca " + newPeriod +
                        " thứ " + newDay + " với môn khác");
            }
        }

        schedule.setDayOfWeek(newDay);
        schedule.setPeriod(newPeriod);

        if (req.getStartDate() != null) section.setStartDate(req.getStartDate());
        if (req.getEndDate() != null) section.setEndDate(req.getEndDate());
        sectionRepository.save(section);
        scheduleRepository.save(schedule);

        if (req.getStudentIds() != null) {
            updateStudentsForSection(section, req.getStudentIds());
        }

        return toDetailResponse(schedule, buildStudentList(section.getId()));
    }

    // ── Soft Delete ──────────────────────────────────────────────────────────

    @Transactional
    public void softDeleteSchedule(Long scheduleId) {
        Schedule s = scheduleRepository.findById(scheduleId)
            .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lịch học"));
        s.setIsDeleted(true);
        scheduleRepository.save(s);
    }

    @Transactional
    public int softDeleteSchedulesBulk(List<Long> ids) {
        if (ids == null || ids.isEmpty())
            throw new IllegalArgumentException("Danh sách lịch học trống");
        for (Long id : ids) {
            Schedule s = scheduleRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lịch học id=" + id));
            s.setIsDeleted(true);
            scheduleRepository.save(s);
        }
        return ids.size();
    }

    // ── Students in schedule ─────────────────────────────────────────────────

    @Transactional
    public AdminScheduleDetailResponse updateStudentsInSchedule(Long scheduleId, List<Long> studentIds) {
        Schedule schedule = scheduleRepository.findByIdWithDetails(scheduleId)
            .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lịch học"));
        updateStudentsForSection(schedule.getSection(), studentIds);
        return toDetailResponse(schedule, buildStudentList(schedule.getSection().getId()));
    }

    private void updateStudentsForSection(Section section, List<Long> studentIds) {
        Long sectionId = section.getId();
        Set<Long> newStudentIds = new HashSet<>(studentIds);

        List<Enrollment> existing = enrollmentRepository.findAllBySection_Id(sectionId);
        Set<Long> currentStudentIds = existing.stream()
                .map(e -> e.getStudent().getId()).collect(Collectors.toSet());

        // Xóa sinh viên bị bỏ
        for (Enrollment e : existing) {
            if (!newStudentIds.contains(e.getStudent().getId())) {
                enrollmentRepository.delete(e);
            }
        }

        // Thêm sinh viên mới
        for (Long studentId : studentIds) {
            if (!currentStudentIds.contains(studentId)) {
                Student student = studentRepository.findById(studentId)
                    .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sinh viên id=" + studentId));
                Enrollment e = new Enrollment();
                e.setStudent(student);
                e.setSection(section);
                enrollmentRepository.save(e);
            }
        }
    }

    // ── Excel Import ─────────────────────────────────────────────────────────

    public Map<String, Object> previewScheduleExcel(MultipartFile file) throws IOException {
        return parseExcel(file);
    }

    @Transactional
    public Map<String, Object> importScheduleExcel(MultipartFile file) throws IOException {
        Map<String, Object> preview = parseExcel(file);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> rows = (List<Map<String, Object>>) preview.get("rows");
        int success = 0;
        for (Map<String, Object> row : rows) {
            if (Boolean.TRUE.equals(row.get("valid"))) {
                try {
                    CreateScheduleRequest req = new CreateScheduleRequest();
                    req.setCourseId(((Number) row.get("courseId")).longValue());
                    req.setIsLab(Boolean.TRUE.equals(row.get("isLab")));
                    req.setSemester(row.get("semester").toString());
                    req.setAcademicYear(row.get("academicYear").toString());
                    if (row.get("startDate") != null)
                        req.setStartDate(LocalDate.parse(row.get("startDate").toString()));
                    if (row.get("endDate") != null)
                        req.setEndDate(LocalDate.parse(row.get("endDate").toString()));
                    req.setRoom(row.get("room") != null ? row.get("room").toString() : null);
                    req.setLecturer(row.get("lecturer") != null ? row.get("lecturer").toString() : null);
                    req.setDayOfWeek(((Number) row.get("dayOfWeek")).intValue());
                    req.setPeriod(((Number) row.get("period")).intValue());
                    createSchedule(req);
                    success++;
                } catch (Exception ignored) {}
            }
        }
        Map<String, Object> result = new LinkedHashMap<>(preview);
        result.put("successCount", success);
        return result;
    }

    private Map<String, Object> parseExcel(MultipartFile file) throws IOException {
        List<String> REQUIRED = List.of("course_code", "is_lab", "semester", "academic_year", "day_of_week", "period");
        List<Map<String, Object>> rows = new ArrayList<>();
        int validCount = 0, invalidCount = 0;

        try (Workbook wb = new XSSFWorkbook(file.getInputStream())) {
            Sheet sheet = wb.getSheetAt(0);
            Row headerRow = sheet.getRow(0);
            if (headerRow == null) {
                return Map.of("rows", rows, "validCount", 0, "invalidCount", 0,
                    "error", "File Excel không có dòng tiêu đề");
            }

            Map<String, Integer> colIndex = new LinkedHashMap<>();
            for (Cell cell : headerRow) {
                String h = cell.getStringCellValue().trim().toLowerCase().replace(" ", "_");
                colIndex.put(h, cell.getColumnIndex());
            }

            for (String req : REQUIRED) {
                if (!colIndex.containsKey(req)) {
                    return Map.of("rows", rows, "validCount", 0, "invalidCount", 0,
                        "error", "Thiếu cột bắt buộc: " + req + ". Cần: " + String.join(", ", REQUIRED));
                }
            }

            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null) continue;

                String courseCode = getCellString(row, colIndex, "course_code");
                String isLabStr = getCellString(row, colIndex, "is_lab");
                String semester = getCellString(row, colIndex, "semester");
                String academicYear = getCellString(row, colIndex, "academic_year");
                String startDateStr = getCellString(row, colIndex, "start_date");
                String endDateStr = getCellString(row, colIndex, "end_date");
                String room = getCellString(row, colIndex, "room");
                String lecturer = getCellString(row, colIndex, "lecturer");
                String dayStr = getCellString(row, colIndex, "day_of_week");
                String periodStr = getCellString(row, colIndex, "period");

                Map<String, Object> rowData = new LinkedHashMap<>();
                rowData.put("row", i + 1);
                rowData.put("courseCode", courseCode);
                rowData.put("semester", semester);
                rowData.put("academicYear", academicYear);
                rowData.put("startDate", startDateStr);
                rowData.put("endDate", endDateStr);
                rowData.put("room", room);
                rowData.put("lecturer", lecturer);
                rowData.put("dayOfWeek", dayStr);
                rowData.put("period", periodStr);

                String error = null;
                if (courseCode == null || courseCode.isBlank()) {
                    error = "Thiếu mã môn học";
                } else {
                    var courseOpt = courseRepository.findByCourseCodeIgnoreCaseAndIsDeletedFalse(courseCode.trim());
                    if (courseOpt.isEmpty()) error = "Môn học không tồn tại: " + courseCode;
                    else {
                        rowData.put("courseName", courseOpt.get().getCourseName());
                        rowData.put("courseId", courseOpt.get().getId());
                    }
                }
                if (error == null && (semester == null || semester.isBlank())) error = "Thiếu học kỳ";
                if (error == null && (academicYear == null || academicYear.isBlank())) error = "Thiếu năm học";
                if (error == null) {
                    try {
                        int day = Integer.parseInt(dayStr != null ? dayStr.trim() : "");
                        if (day < 2 || day > 8) error = "Thứ trong tuần phải 2-8";
                        else rowData.put("dayOfWeek", day);
                    } catch (NumberFormatException e) { error = "Thứ trong tuần không hợp lệ"; }
                }
                if (error == null) {
                    try {
                        int period = Integer.parseInt(periodStr != null ? periodStr.trim() : "");
                        if (period < 1 || period > 4) error = "Ca học phải 1-4";
                        else rowData.put("period", period);
                    } catch (NumberFormatException e) { error = "Ca học không hợp lệ"; }
                }

                boolean isLab = "true".equalsIgnoreCase(isLabStr) || "1".equals(isLabStr) || "th".equalsIgnoreCase(isLabStr);
                rowData.put("isLab", isLab);

                if (error == null) { rowData.put("valid", true); validCount++; }
                else { rowData.put("valid", false); rowData.put("error", error); invalidCount++; }
                rows.add(rowData);
            }
        }
        return Map.of("rows", rows, "validCount", validCount, "invalidCount", invalidCount);
    }

    // ── Section Management ───────────────────────────────────────────────────

    public List<AdminSectionListResponse> getSections(String keyword, String semester, String academicYear) {
        String kw = (keyword == null || keyword.isBlank()) ? null : keyword.trim();
        String sem = (semester == null || semester.isBlank()) ? null : semester.trim();
        String ay = (academicYear == null || academicYear.isBlank()) ? null : academicYear.trim();
        return sectionRepository.findAllWithFilters(kw, sem, ay).stream()
                .map(sec -> {
                    long studentCount = enrollmentRepository.countBySection_Id(sec.getId());
                    long scheduleCount = scheduleRepository.findActiveBySectionId(sec.getId()).size();
                    DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyy-MM-dd");
                    return AdminSectionListResponse.builder()
                            .sectionId(sec.getId())
                            .courseId(sec.getCourse().getId())
                            .courseCode(sec.getCourse().getCourseCode())
                            .courseName(sec.getCourse().getCourseName())
                            .credits(sec.getCourse().getCredits())
                            .groupNumber(sec.getGroupNumber())
                            .teamNumber(sec.getTeamNumber())
                            .semester(sec.getSemester())
                            .academicYear(sec.getAcademicYear())
                            .startDate(sec.getStartDate() != null ? sec.getStartDate().format(fmt) : null)
                            .endDate(sec.getEndDate() != null ? sec.getEndDate().format(fmt) : null)
                            .studentCount((int) studentCount)
                            .scheduleCount((int) scheduleCount)
                            .build();
                })
                .collect(Collectors.toList());
    }

    public List<String> getDistinctSectionAcademicYears() {
        return sectionRepository.findDistinctAcademicYears();
    }

    public AdminSectionDetailResponse getSectionDetail(Long sectionId) {
        Section sec = sectionRepository.findActiveById(sectionId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy học phần"));
        return buildSectionDetail(sec);
    }

    @Transactional
    public AdminSectionDetailResponse createSection(CreateSectionRequest req) {
        if (req.getCourseId() == null) throw new IllegalArgumentException("Vui lòng chọn môn học");
        if (req.getSemester() == null || req.getSemester().isBlank()) throw new IllegalArgumentException("Vui lòng nhập học kỳ");
        if (req.getAcademicYear() == null || req.getAcademicYear().isBlank()) throw new IllegalArgumentException("Vui lòng nhập năm học");
        validateSectionDates(req.getAcademicYear().trim(), req.getStartDate(), req.getEndDate());
        Integer groupNumber = validateGroupOrTeam(req.getGroupNumber(), "Số nhóm");
        Integer teamNumber = validateGroupOrTeam(req.getTeamNumber(), "Số tổ");
        Course course = courseRepository.findById(req.getCourseId())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy môn học"));
        if (sectionRepository.existsByCourse_IdAndSemesterAndAcademicYearAndGroupNumberAndTeamNumberAndIsDeletedFalse(
                req.getCourseId(), req.getSemester().trim(), req.getAcademicYear().trim(), groupNumber, teamNumber)) {
            throw new IllegalArgumentException("Học phần này đã tồn tại (cùng môn, kỳ, năm, nhóm, tổ)");
        }
        Section sec = new Section();
        sec.setCourse(course);
        sec.setSemester(req.getSemester().trim());
        sec.setAcademicYear(req.getAcademicYear().trim());
        sec.setStartDate(req.getStartDate());
        sec.setEndDate(req.getEndDate());
        sec.setGroupNumber(groupNumber);
        sec.setTeamNumber(teamNumber);
        sectionRepository.save(sec);
        return buildSectionDetail(sec);
    }

    @Transactional
    public AdminSectionDetailResponse updateSection(Long sectionId, CreateSectionRequest req) {
        Section sec = sectionRepository.findActiveById(sectionId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy học phần"));
        String academicYear = (req.getAcademicYear() != null && !req.getAcademicYear().isBlank())
                ? req.getAcademicYear().trim() : sec.getAcademicYear();
        LocalDate startDate = req.getStartDate() != null ? req.getStartDate() : sec.getStartDate();
        LocalDate endDate = req.getEndDate() != null ? req.getEndDate() : sec.getEndDate();
        validateSectionDates(academicYear, startDate, endDate);
        sec.setAcademicYear(academicYear);
        sec.setStartDate(startDate);
        sec.setEndDate(endDate);
        if (req.getSemester() != null && !req.getSemester().isBlank()) sec.setSemester(req.getSemester().trim());
        if (req.getGroupNumber() != null) sec.setGroupNumber(validateGroupOrTeam(req.getGroupNumber(), "Số nhóm"));
        if (req.getTeamNumber() != null) sec.setTeamNumber(validateGroupOrTeam(req.getTeamNumber(), "Số tổ"));
        sectionRepository.save(sec);
        return buildSectionDetail(sec);
    }

    /**
     * Validate năm học, ngày bắt đầu, ngày kết thúc của một học phần.
     * - academicYear phải đúng định dạng yyyy-yyyy và năm sau = năm trước + 1
     * - startDate và endDate không được null
     * - endDate phải sau startDate
     * - startDate và endDate phải nằm trong phạm vi [01-01-yearStart, 31-12-yearEnd]
     */
    private void validateSectionDates(String academicYear, LocalDate startDate, LocalDate endDate) {
        // Validate format yyyy-yyyy
        if (!academicYear.matches("^\\d{4}-\\d{4}$"))
            throw new IllegalArgumentException("Năm học phải theo định dạng yyyy-yyyy (ví dụ: 2025-2026)");
        int yearStart = Integer.parseInt(academicYear.substring(0, 4));
        int yearEnd   = Integer.parseInt(academicYear.substring(5));
        if (yearEnd != yearStart + 1)
            throw new IllegalArgumentException("Năm học không hợp lệ: năm sau phải bằng năm trước + 1 (ví dụ: 2025-2026)");

        // Validate ngày không null
        if (startDate == null) throw new IllegalArgumentException("Ngày bắt đầu không được để trống");
        if (endDate == null)   throw new IllegalArgumentException("Ngày kết thúc không được để trống");

        // Validate endDate > startDate
        if (!endDate.isAfter(startDate))
            throw new IllegalArgumentException("Ngày kết thúc phải sau ngày bắt đầu");

        // Validate nằm trong phạm vi năm học
        LocalDate rangeStart = LocalDate.of(yearStart, 1, 1);
        LocalDate rangeEnd   = LocalDate.of(yearEnd, 12, 31);
        if (startDate.isBefore(rangeStart) || startDate.isAfter(rangeEnd))
            throw new IllegalArgumentException(
                    "Ngày bắt đầu phải nằm trong năm học " + academicYear
                    + " (từ " + rangeStart + " đến " + rangeEnd + ")");
        if (endDate.isBefore(rangeStart) || endDate.isAfter(rangeEnd))
            throw new IllegalArgumentException(
                    "Ngày kết thúc phải nằm trong năm học " + academicYear
                    + " (từ " + rangeStart + " đến " + rangeEnd + ")");
    }

    @Transactional
    public void deleteSection(Long sectionId) {
        Section sec = sectionRepository.findActiveById(sectionId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy học phần"));
        // Soft delete tất cả schedules thuộc section
        scheduleRepository.findActiveBySectionId(sectionId)
                .forEach(s -> { s.setIsDeleted(true); scheduleRepository.save(s); });
        // Soft delete section
        sec.setIsDeleted(true);
        sectionRepository.save(sec);
    }

    @Transactional
    public int deleteSectionsBulk(List<Long> ids) {
        for (Long id : ids) deleteSection(id);
        return ids.size();
    }

    // ── Schedule within a Section ─────────────────────────────────────────────

    @Transactional
    public AdminSectionDetailResponse addScheduleToSection(Long sectionId, CreateSectionScheduleRequest req) {
        Section sec = sectionRepository.findActiveById(sectionId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy học phần"));
        if (req.getDayOfWeek() == null || req.getDayOfWeek() < 2 || req.getDayOfWeek() > 8)
            throw new IllegalArgumentException("Thứ trong tuần không hợp lệ (2-8)");
        if (req.getPeriod() == null || req.getPeriod() < 1 || req.getPeriod() > 4)
            throw new IllegalArgumentException("Ca học không hợp lệ (1-4)");
        validateRoomAndLecturer(req.getRoom(), req.getLecturer());

        // Kiểm tra trùng ca trong cùng section này (cùng ngày + ca)
        if (scheduleRepository.existsDuplicateInSection(sectionId, req.getDayOfWeek(), req.getPeriod(), null))
            throw new IllegalArgumentException(
                    "Học phần này đã có ca học vào " + _dayLabel(req.getDayOfWeek()) + " ca " + req.getPeriod());

        if (req.getLecturer() != null && !req.getLecturer().isBlank()) {
            boolean lecturerConflict = scheduleRepository.existsLecturerConflict(
                    req.getLecturer(), sec.getSemester(), sec.getAcademicYear(),
                    req.getDayOfWeek(), req.getPeriod(), null);
            if (lecturerConflict) throw new IllegalArgumentException(
                    "Giảng viên \"" + req.getLecturer() + "\" đã có lịch dạy môn khác trong ca này");
        }

        // Kiểm tra conflict cho từng sinh viên trong section
        List<Enrollment> enrollments = enrollmentRepository.findAllBySection_Id(sectionId);
        for (Enrollment e : enrollments) {
            List<Enrollment> conflicts = enrollmentRepository.findStudentConflicts(
                    e.getStudent().getId(), sec.getSemester(), sec.getAcademicYear(),
                    req.getDayOfWeek(), req.getPeriod(), sectionId);
            if (!conflicts.isEmpty()) {
                throw new IllegalArgumentException(
                        "Sinh viên " + e.getStudent().getStudentCode() + " bị trùng ca với môn khác");
            }
        }

        Schedule schedule = new Schedule();
        schedule.setSection(sec);
        schedule.setDayOfWeek(req.getDayOfWeek());
        schedule.setPeriod(req.getPeriod());
        schedule.setRoom(req.getRoom());
        schedule.setLecturer(req.getLecturer());
        schedule.setIsLab(Boolean.TRUE.equals(req.getIsLab()));
        schedule.setIsDeleted(false);
        scheduleRepository.save(schedule);
        return buildSectionDetail(sec);
    }

    @Transactional
    public AdminSectionDetailResponse updateScheduleInSection(Long scheduleId, CreateSectionScheduleRequest req) {
        Schedule schedule = scheduleRepository.findByIdWithDetails(scheduleId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lịch học"));
        Section sec = schedule.getSection();
        int newDay = req.getDayOfWeek() != null ? req.getDayOfWeek() : schedule.getDayOfWeek();
        int newPeriod = req.getPeriod() != null ? req.getPeriod() : schedule.getPeriod();
        if (newDay < 2 || newDay > 8) throw new IllegalArgumentException("Thứ trong tuần không hợp lệ (2-8)");
        if (newPeriod < 1 || newPeriod > 4) throw new IllegalArgumentException("Ca học không hợp lệ (1-4)");
        String newRoom = (req.getRoom() != null && !req.getRoom().isBlank())
                ? req.getRoom().trim() : schedule.getRoom();
        String newLecturer = (req.getLecturer() != null && !req.getLecturer().isBlank())
                ? req.getLecturer().trim() : schedule.getLecturer();
        validateRoomAndLecturer(newRoom, newLecturer);

        // Kiểm tra trùng ca trong cùng section này (cùng ngày + ca, bỏ qua ca đang sửa)
        if (scheduleRepository.existsDuplicateInSection(sec.getId(), newDay, newPeriod, scheduleId))
            throw new IllegalArgumentException(
                    "Học phần này đã có ca học vào " + _dayLabel(newDay) + " ca " + newPeriod);

        if (newLecturer != null && !newLecturer.isBlank()) {
            boolean lecturerConflict = scheduleRepository.existsLecturerConflict(
                    newLecturer, sec.getSemester(), sec.getAcademicYear(), newDay, newPeriod, scheduleId);
            if (lecturerConflict) throw new IllegalArgumentException(
                    "Giảng viên \"" + newLecturer + "\" đã có lịch dạy môn khác trong ca này");
        }

        // Kiểm tra conflict lịch học cho sinh viên đang đăng ký học phần này
        List<Enrollment> enrollments = enrollmentRepository.findAllBySection_Id(sec.getId());
        for (Enrollment e : enrollments) {
            List<Enrollment> conflicts = enrollmentRepository.findStudentConflicts(
                    e.getStudent().getId(), sec.getSemester(), sec.getAcademicYear(),
                    newDay, newPeriod, sec.getId());
            if (!conflicts.isEmpty()) {
                throw new IllegalArgumentException(
                        "Sinh viên " + e.getStudent().getStudentCode() + " bị trùng ca " + newPeriod +
                        " thứ " + newDay + " với môn khác");
            }
        }

        schedule.setDayOfWeek(newDay);
        schedule.setPeriod(newPeriod);
        schedule.setRoom(newRoom);
        schedule.setLecturer(newLecturer);
        if (req.getIsLab() != null) schedule.setIsLab(req.getIsLab());
        scheduleRepository.save(schedule);
        return buildSectionDetail(sec);
    }

    // ── Students in Section ───────────────────────────────────────────────────

    @Transactional
    public AdminSectionDetailResponse updateStudentsInSection(Long sectionId, List<Long> studentIds) {
        Section sec = sectionRepository.findActiveById(sectionId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy học phần"));
        // Lấy schedules của section để check conflict
        List<Schedule> schedules = scheduleRepository.findActiveBySectionId(sectionId);
        Set<Long> newStudentIds = new HashSet<>(studentIds);
        List<Enrollment> existing = enrollmentRepository.findAllBySection_Id(sectionId);
        Set<Long> currentIds = existing.stream().map(e -> e.getStudent().getId()).collect(Collectors.toSet());

        // Xóa SV bị bỏ
        for (Enrollment e : existing) {
            if (!newStudentIds.contains(e.getStudent().getId())) {
                enrollmentRepository.delete(e);
            }
        }

        // Thêm SV mới, check conflict với từng ca của section
        for (Long studentId : studentIds) {
            if (!currentIds.contains(studentId)) {
                Student student = studentRepository.findById(studentId)
                        .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sinh viên id=" + studentId));
                for (Schedule sch : schedules) {
                    List<Enrollment> conflicts = enrollmentRepository.findStudentConflicts(
                            studentId, sec.getSemester(), sec.getAcademicYear(),
                            sch.getDayOfWeek(), sch.getPeriod(), sectionId);
                    if (!conflicts.isEmpty()) {
                        throw new IllegalArgumentException(
                                "Sinh viên " + student.getStudentCode() + " bị trùng ca " + sch.getPeriod() +
                                " thứ " + sch.getDayOfWeek() + " với môn khác");
                    }
                }
                Enrollment e = new Enrollment();
                e.setStudent(student);
                e.setSection(sec);
                enrollmentRepository.save(e);
            }
        }
        return buildSectionDetail(sec);
    }

    private AdminSectionDetailResponse buildSectionDetail(Section sec) {
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        List<SectionScheduleResponse> schedules = scheduleRepository.findActiveBySectionId(sec.getId())
                .stream().map(s -> {
                    String[] times = PERIOD_TIMES.getOrDefault(s.getPeriod(), new String[]{"", ""});
                    return SectionScheduleResponse.builder()
                            .scheduleId(s.getId())
                            .dayOfWeek(s.getDayOfWeek())
                            .period(s.getPeriod())
                            .periodStart(times[0])
                            .periodEnd(times[1])
                            .room(s.getRoom())
                            .lecturer(s.getLecturer())
                            .isLab(s.getIsLab())
                            .build();
                }).collect(Collectors.toList());
        List<StudentInScheduleResponse> students = enrollmentRepository.findBySectionIdWithStudent(sec.getId())
                .stream().map(e -> StudentInScheduleResponse.builder()
                        .studentId(e.getStudent().getId())
                        .studentCode(e.getStudent().getStudentCode())
                        .fullName(e.getStudent().getFullName())
                        .build()).collect(Collectors.toList());
        return AdminSectionDetailResponse.builder()
                .sectionId(sec.getId())
                .courseId(sec.getCourse().getId())
                .courseCode(sec.getCourse().getCourseCode())
                .courseName(sec.getCourse().getCourseName())
                .credits(sec.getCourse().getCredits())
                .groupNumber(sec.getGroupNumber())
                .teamNumber(sec.getTeamNumber())
                .semester(sec.getSemester())
                .academicYear(sec.getAcademicYear())
                .startDate(sec.getStartDate() != null ? sec.getStartDate().format(fmt) : null)
                .endDate(sec.getEndDate() != null ? sec.getEndDate().format(fmt) : null)
                .schedules(schedules)
                .students(students)
                .build();
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private void validateScheduleFields(Long courseId, String semester, String academicYear, Integer dayOfWeek, Integer period) {
        if (courseId == null) throw new IllegalArgumentException("Vui lòng chọn môn học");
        if (semester == null || semester.isBlank()) throw new IllegalArgumentException("Vui lòng nhập học kỳ");
        if (academicYear == null || academicYear.isBlank()) throw new IllegalArgumentException("Vui lòng nhập năm học");
        if (dayOfWeek == null || dayOfWeek < 2 || dayOfWeek > 8) throw new IllegalArgumentException("Thứ trong tuần không hợp lệ (2-8)");
        if (period == null || period < 1 || period > 4) throw new IllegalArgumentException("Ca học không hợp lệ (1-4)");
    }

    private String _dayLabel(int day) {
        return switch (day) {
            case 2 -> "Thứ 2"; case 3 -> "Thứ 3"; case 4 -> "Thứ 4";
            case 5 -> "Thứ 5"; case 6 -> "Thứ 6"; case 7 -> "Thứ 7";
            default -> "Chủ nhật";
        };
    }

    /**
     * Validate phòng học và giảng viên:
     * - Không được rỗng
     * - Tên giảng viên chỉ chứa chữ cái, khoảng trắng và dấu tiếng Việt (không có số hay ký tự đặc biệt)
     * - Tên phòng không chứa ký tự đặc biệt (chỉ chữ cái, số, dấu cách, dấu gạch ngang)
     */
    private void validateRoomAndLecturer(String room, String lecturer) {
        if (room == null || room.isBlank())
            throw new IllegalArgumentException("Phòng học không được để trống");
        if (lecturer == null || lecturer.isBlank())
            throw new IllegalArgumentException("Giảng viên không được để trống");
        // Phòng: chỉ cho phép chữ cái, số, khoảng trắng, dấu chấm, dấu gạch ngang
        if (!room.trim().matches("[\\p{L}\\d\\s.\\-]+"))
            throw new IllegalArgumentException("Tên phòng không được chứa ký tự đặc biệt");
        // Giảng viên: chỉ chữ cái (bao gồm Unicode/tiếng Việt) và khoảng trắng, không có số
        if (!lecturer.trim().matches("[\\p{L}\\s]+"))
            throw new IllegalArgumentException("Tên giảng viên không được chứa số hoặc ký tự đặc biệt");
    }

    private List<StudentInScheduleResponse> buildStudentList(Long sectionId) {
        return enrollmentRepository.findBySectionIdWithStudent(sectionId)
            .stream()
            .map(e -> StudentInScheduleResponse.builder()
                .studentId(e.getStudent().getId())
                .studentCode(e.getStudent().getStudentCode())
                .fullName(e.getStudent().getFullName())
                .build())
            .collect(Collectors.toList());
    }

    private AdminScheduleListResponse toListResponse(Schedule s, long studentCount) {
        Section sec = s.getSection();
        String[] times = PERIOD_TIMES.getOrDefault(s.getPeriod(), new String[]{"", ""});
        return AdminScheduleListResponse.builder()
            .scheduleId(s.getId())
            .sectionId(sec.getId())
            .courseId(sec.getCourse().getId())
            .courseCode(sec.getCourse().getCourseCode())
            .courseName(sec.getCourse().getCourseName())
            .credits(sec.getCourse().getCredits())
            .isLab(s.getIsLab())
            .semester(sec.getSemester())
            .academicYear(sec.getAcademicYear())
            .room(s.getRoom())
            .lecturer(s.getLecturer())
            .dayOfWeek(s.getDayOfWeek())
            .period(s.getPeriod())
            .periodStart(times[0])
            .periodEnd(times[1])
            .studentCount((int) studentCount)
            .build();
    }

    private AdminScheduleDetailResponse toDetailResponse(Schedule s, List<StudentInScheduleResponse> students) {
        Section sec = s.getSection();
        String[] times = PERIOD_TIMES.getOrDefault(s.getPeriod(), new String[]{"", ""});
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        return AdminScheduleDetailResponse.builder()
            .scheduleId(s.getId())
            .sectionId(sec.getId())
            .courseId(sec.getCourse().getId())
            .courseCode(sec.getCourse().getCourseCode())
            .courseName(sec.getCourse().getCourseName())
            .credits(sec.getCourse().getCredits())
            .isLab(s.getIsLab())
            .semester(sec.getSemester())
            .academicYear(sec.getAcademicYear())
            .startDate(sec.getStartDate() != null ? sec.getStartDate().format(fmt) : null)
            .endDate(sec.getEndDate() != null ? sec.getEndDate().format(fmt) : null)
            .room(s.getRoom())
            .lecturer(s.getLecturer())
            .dayOfWeek(s.getDayOfWeek())
            .period(s.getPeriod())
            .periodStart(times[0])
            .periodEnd(times[1])
            .students(students)
            .build();
    }

    /**
     * Validate số nhóm hoặc số tổ:
     * - Không được null/trống
     * - Chỉ chứa chữ số, không chứa chữ cái hay ký tự đặc biệt
     * - Phải là số nguyên dương
     */
    private Integer validateGroupOrTeam(String value, String label) {
        if (value == null || value.isBlank())
            throw new IllegalArgumentException(label + " không được để trống");
        if (!value.trim().matches("^[0-9]+$"))
            throw new IllegalArgumentException(label + " chỉ được chứa chữ số (không được có chữ cái hoặc ký tự đặc biệt)");
        int num = Integer.parseInt(value.trim());
        if (num < 1)
            throw new IllegalArgumentException(label + " phải là số nguyên dương");
        return num;
    }

    private String getCellString(Row row, Map<String, Integer> colIndex, String col) {
        Integer idx = colIndex.get(col);
        if (idx == null) return null;
        Cell cell = row.getCell(idx);
        if (cell == null) return null;
        return switch (cell.getCellType()) {
            case STRING -> cell.getStringCellValue().trim();
            case NUMERIC -> {
                double v = cell.getNumericCellValue();
                if (v == Math.floor(v)) yield String.valueOf((long) v);
                yield String.valueOf(v);
            }
            case BOOLEAN -> String.valueOf(cell.getBooleanCellValue());
            default -> null;
        };
    }

    public ScheduleService getScheduleService() { return scheduleService; }
}
