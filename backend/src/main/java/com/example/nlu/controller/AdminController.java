package com.example.nlu.controller;

import com.example.nlu.dto.request.AdminDeleteNotificationGroupRequest;
import com.example.nlu.dto.request.AdminSendNotificationRequest;
import com.example.nlu.dto.request.CreateStudentRequest;
import com.example.nlu.dto.request.StudentIdsRequest;
import com.example.nlu.dto.request.UpdateScheduleRequest;
import com.example.nlu.dto.request.UpdateStudentRequest;
import com.example.nlu.dto.request.CreateScheduleRequest;
import com.example.nlu.dto.request.UpdateScheduleAdminRequest;
import com.example.nlu.dto.request.CreateSectionRequest;
import com.example.nlu.dto.request.CreateSectionScheduleRequest;
import com.example.nlu.dto.response.AdminStudentResponse;
import com.example.nlu.dto.response.GradeResponse;
import com.example.nlu.entity.Course;
import com.example.nlu.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class AdminController {

    private final AdminStudentService adminStudentService;
    private final AdminAcademicService adminAcademicService;
    private final AdminProgramService adminProgramService;
    private final AdminScheduleService adminScheduleService;
    private final GradeService gradeService;
    private final AdminUserService adminUserService;
    private final AdminChatbotService adminChatbotService;
    private final AdminNotificationService adminNotificationService;

    @GetMapping("/students")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudents(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String className,
            @RequestParam(required = false) String faculty,
            @RequestParam(required = false) Integer startYear,
            @RequestParam(required = false) String status
    ) {
        try {
            List<AdminStudentResponse> result = adminStudentService.getStudents(keyword, className, faculty, startYear, status);
            return ResponseEntity.ok(Map.of("total", result.size(), "data", result));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @GetMapping("/students/filter-suggestions")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentFilterSuggestions(
            @RequestParam String type,
            @RequestParam(required = false) String keyword
    ) {
        try {
            return ResponseEntity.ok(Map.of("data", adminStudentService.getFilterSuggestions(type, keyword)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/students/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentDetail(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(Map.of("data", adminStudentService.getStudentDetail(id)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/students")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createStudent(@RequestBody CreateStudentRequest request) {
        try {
            AdminStudentResponse result = adminStudentService.createStudent(request);
            return ResponseEntity.ok(Map.of("message", "Thêm sinh viên thành công", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PutMapping("/students/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateStudent(@PathVariable Long id,
                                           @RequestBody UpdateStudentRequest request) {
        try {
            AdminStudentResponse result = adminStudentService.updateStudent(id, request);
            return ResponseEntity.ok(Map.of("message", "Cập nhật sinh viên thành công", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/students/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteStudent(@PathVariable Long id) {
        try {
            adminStudentService.deleteStudent(id);
            return ResponseEntity.ok(Map.of("message", "Đã vô hiệu hóa sinh viên"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/students")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteStudentsBulk(@RequestBody StudentIdsRequest request) {
        try {
            int count = adminStudentService.deleteStudentsBulk(request.getIds());
            return ResponseEntity.ok(Map.of("message", "Đã vô hiệu hóa " + count + " sinh viên"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @GetMapping("/programs/faculties")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getProgramFaculties() {
        return ResponseEntity.ok(Map.of("data", adminProgramService.getFaculties()));
    }

    @GetMapping("/programs/majors")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getProgramMajors(@RequestParam String faculty) {
        try {
            return ResponseEntity.ok(Map.of("data", adminProgramService.getMajors(faculty)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/programs/specializations")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getProgramSpecializations(
            @RequestParam String faculty,
            @RequestParam String major
    ) {
        try {
            return ResponseEntity.ok(Map.of("data", adminProgramService.getSpecializations(faculty, major)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/programs/resolve")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> resolveProgram(
            @RequestParam String faculty,
            @RequestParam String major,
            @RequestParam String specialization
    ) {
        try {
            return ResponseEntity.ok(Map.of("data", adminProgramService.resolveProgramId(faculty, major, specialization)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/students/{id}/schedule/latest")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentLatestSchedule(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(Map.of("data", adminScheduleService.getScheduleService().getLatestSchedule(
                    studentRepository(id))));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    // ── Admin Schedule Management ────────────────────────────────────────────

    @GetMapping("/schedules")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getAdminSchedules(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String semester,
            @RequestParam(required = false) String academicYear
    ) {
        try {
            var list = adminScheduleService.getSchedules(keyword, semester, academicYear);
            return ResponseEntity.ok(Map.of("total", list.size(), "data", list));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @GetMapping("/schedules/academic-years")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getScheduleAcademicYears() {
        return ResponseEntity.ok(Map.of("data", adminScheduleService.getDistinctAcademicYears()));
    }

    @GetMapping("/schedules/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getAdminScheduleDetail(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(Map.of("data", adminScheduleService.getScheduleDetail(id)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/schedules")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createAdminSchedule(@RequestBody CreateScheduleRequest request) {
        try {
            var result = adminScheduleService.createSchedule(request);
            return ResponseEntity.ok(Map.of("message", "Thêm lịch học thành công", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PutMapping("/schedules/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateAdminSchedule(@PathVariable Long id,
                                                  @RequestBody UpdateScheduleAdminRequest request) {
        try {
            return ResponseEntity.ok(Map.of(
                    "message", "Cập nhật lịch học thành công",
                    "data", adminScheduleService.updateSchedule(id, request)
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/schedules/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> softDeleteSchedule(@PathVariable Long id) {
        try {
            adminScheduleService.softDeleteSchedule(id);
            return ResponseEntity.ok(Map.of("message", "Xóa lịch học thành công"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/schedules")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> softDeleteSchedulesBulk(@RequestBody Map<String, List<Long>> request) {
        try {
            int count = adminScheduleService.softDeleteSchedulesBulk(request.get("ids"));
            return ResponseEntity.ok(Map.of("message", "Đã xóa " + count + " lịch học"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PutMapping("/schedules/{id}/students")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateScheduleStudents(@PathVariable Long id,
                                                     @RequestBody Map<String, List<Long>> request) {
        try {
            var result = adminScheduleService.updateStudentsInSchedule(id, request.get("studentIds"));
            return ResponseEntity.ok(Map.of("message", "Cập nhật danh sách sinh viên thành công", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/schedules/preview")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> previewSchedules(@RequestParam("file") MultipartFile file) {
        try {
            return ResponseEntity.ok(Map.of("data", adminScheduleService.previewScheduleExcel(file)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/schedules/import")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> importSchedules(@RequestParam("file") MultipartFile file) {
        try {
            var result = adminScheduleService.importScheduleExcel(file);
            return ResponseEntity.ok(Map.of("message", "Import lịch học hoàn tất", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    // ── Admin Section Management ─────────────────────────────────────────────

    @GetMapping("/sections")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getAdminSections(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String semester,
            @RequestParam(required = false) String academicYear
    ) {
        try {
            var list = adminScheduleService.getSections(keyword, semester, academicYear);
            return ResponseEntity.ok(Map.of("total", list.size(), "data", list));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @GetMapping("/sections/academic-years")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getSectionAcademicYears() {
        return ResponseEntity.ok(Map.of("data", adminScheduleService.getDistinctSectionAcademicYears()));
    }

    @GetMapping("/sections/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getAdminSectionDetail(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(Map.of("data", adminScheduleService.getSectionDetail(id)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/sections")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createAdminSection(@RequestBody CreateSectionRequest request) {
        try {
            var result = adminScheduleService.createSection(request);
            return ResponseEntity.ok(Map.of("message", "Thêm học phần thành công", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PutMapping("/sections/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateAdminSection(@PathVariable Long id,
                                                 @RequestBody CreateSectionRequest request) {
        try {
            var result = adminScheduleService.updateSection(id, request);
            return ResponseEntity.ok(Map.of("message", "Cập nhật học phần thành công", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/sections/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteAdminSection(@PathVariable Long id) {
        try {
            adminScheduleService.deleteSection(id);
            return ResponseEntity.ok(Map.of("message", "Xóa học phần thành công"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/sections")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteAdminSectionsBulk(@RequestBody Map<String, List<Long>> request) {
        try {
            int count = adminScheduleService.deleteSectionsBulk(request.get("ids"));
            return ResponseEntity.ok(Map.of("message", "Đã xóa " + count + " học phần"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    // ── Schedules within a Section ───────────────────────────────────────────

    @PostMapping("/sections/{id}/schedules")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> addScheduleToSection(@PathVariable Long id,
                                                   @RequestBody CreateSectionScheduleRequest request) {
        try {
            var result = adminScheduleService.addScheduleToSection(id, request);
            return ResponseEntity.ok(Map.of("message", "Thêm lịch học thành công", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PutMapping("/sections/schedules/{scheduleId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateScheduleInSection(@PathVariable Long scheduleId,
                                                      @RequestBody CreateSectionScheduleRequest request) {
        try {
            var result = adminScheduleService.updateScheduleInSection(scheduleId, request);
            return ResponseEntity.ok(Map.of("message", "Cập nhật lịch học thành công", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/sections/schedules/{scheduleId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteScheduleInSection(@PathVariable Long scheduleId) {
        try {
            adminScheduleService.softDeleteSchedule(scheduleId);
            return ResponseEntity.ok(Map.of("message", "Xóa lịch học thành công"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    // ── Students within a Section ────────────────────────────────────────────

    @PutMapping("/sections/{id}/students")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateSectionStudents(@PathVariable Long id,
                                                    @RequestBody Map<String, List<Long>> request) {
        try {
            var result = adminScheduleService.updateStudentsInSection(id, request.get("studentIds"));
            return ResponseEntity.ok(Map.of("message", "Cập nhật danh sách sinh viên thành công", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/sections/{id}/students/preview")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> previewSectionStudentsExcel(@PathVariable Long id,
                                                          @RequestParam("file") MultipartFile file) {
        try {
            var result = adminScheduleService.previewSectionStudentsExcel(id, file);
            return ResponseEntity.ok(Map.of("data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/sections/{id}/students/import")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> importSectionStudentsExcel(@PathVariable Long id,
                                                         @RequestParam("file") MultipartFile file) {
        try {
            var result = adminScheduleService.importSectionStudentsExcel(id, file);
            return ResponseEntity.ok(Map.of("message", "Import sinh viên hoàn tất", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    // ── Section Excel Import ─────────────────────────────────────────────────

    @PostMapping("/sections/preview")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> previewSectionsExcel(@RequestParam("file") MultipartFile file) {
        try {
            return ResponseEntity.ok(Map.of("data", adminScheduleService.previewSectionExcel(file)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/sections/import")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> importSectionsExcel(@RequestParam("file") MultipartFile file) {
        try {
            var result = adminScheduleService.importSectionExcel(file);
            return ResponseEntity.ok(Map.of("message", "Import học phần hoàn tất", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    private String studentRepository(Long id) {
        return adminStudentService.getStudentDetail(id).getStudentCode();
    }

    // ── Admin Chatbot Logs ────────────────────────────────────────────────────

    @GetMapping("/chatbot/logs")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getChatbotLogs(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Boolean flagged
    ) {
        try {
            var list = adminChatbotService.getLogs(keyword, flagged);
            return ResponseEntity.ok(Map.of("total", list.size(), "data", list));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @GetMapping("/chatbot/logs/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getChatbotLogDetail(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(Map.of("data", adminChatbotService.getLogDetail(id)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PutMapping("/chatbot/logs/flag")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> flagChatbotLogs(@RequestBody Map<String, Object> request) {
        try {
            @SuppressWarnings("unchecked")
            List<Long> ids = ((List<Number>) request.get("ids")).stream().map(Number::longValue).toList();
            boolean flagged = Boolean.TRUE.equals(request.get("flagged"));
            adminChatbotService.flagLogs(ids, flagged);
            String action = flagged ? "Đã gắn cờ vi phạm" : "Đã bỏ gắn cờ";
            return ResponseEntity.ok(Map.of("message", action + " " + ids.size() + " log chat"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/chatbot/logs")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteChatbotLogs(@RequestBody Map<String, List<Long>> request) {
        try {
            adminChatbotService.deleteLogs(request.get("ids"));
            return ResponseEntity.ok(Map.of("message", "Đã xóa log chat"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @GetMapping("/students/{id}/grades/semesters")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentGradeSemesters(@PathVariable Long id) {
        try {
            var detail = adminStudentService.getStudentDetail(id);
            return ResponseEntity.ok(Map.of(
                    "data", gradeService.getAvailableSemesters(detail.getStudentCode())
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/students/{id}/grades")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentGrades(
            @PathVariable Long id,
            @RequestParam("academic_year") String academicYear,
            @RequestParam String semester
    ) {
        try {
            var detail = adminStudentService.getStudentDetail(id);
            String mssv = detail.getStudentCode();
            GradeResponse grades = gradeService.getGrades(mssv, academicYear, semester);
            var summary = gradeService.getSemesterSummary(mssv, academicYear, semester);
            return ResponseEntity.ok(Map.of("data", Map.of(
                    "semester", grades.getSemester(),
                    "academicYear", grades.getAcademicYear(),
                    "grades", grades.getGrades(),
                    "semesterSummary", summary
            )));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/courses")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getCourses() {
        List<Course> courses = adminAcademicService.getCourses();
        return ResponseEntity.ok(Map.of("total", courses.size(), "data", courses));
    }

    @PostMapping("/courses")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createCourse(@RequestBody Map<String, Object> request) {
        try {
            Course course = adminAcademicService.createCourse(
                    (String) request.get("course_code"),
                    (String) request.get("name"),
                    request.get("credits") == null ? null : ((Number) request.get("credits")).intValue()
            );
            return ResponseEntity.ok(Map.of("message", "Thêm môn học thành công", "data", course));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PutMapping("/courses/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateCourse(@PathVariable Long id, @RequestBody Map<String, Object> request) {
        try {
            Course course = adminAcademicService.updateCourse(
                    id,
                    (String) request.get("course_code"),
                    (String) request.get("name"),
                    request.get("credits") == null ? null : ((Number) request.get("credits")).intValue()
            );
            return ResponseEntity.ok(Map.of("message", "Cập nhật môn học thành công", "data", course));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/courses/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteCourse(@PathVariable Long id) {
        try {
            adminAcademicService.deleteCourse(id);
            return ResponseEntity.ok(Map.of("message", "Xóa môn học thành công"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/courses/preview")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> previewCourses(@RequestParam("file") MultipartFile file) {
        try {
            Map<String, Object> result = adminAcademicService.previewCourses(file);
            return ResponseEntity.ok(Map.of("data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/courses/import")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> importCourses(@RequestParam("file") MultipartFile file) {
        try {
            Map<String, Object> result = adminAcademicService.importCourses(file);
            return ResponseEntity.ok(Map.of("message", "Import môn học hoàn tất", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/grades/manual")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> upsertManualGrade(@RequestBody Map<String, Object> request) {
        try {
            Map<String, Object> result = adminAcademicService.upsertManualGradeWithTerm(
                    (String) request.get("mssv"),
                    (String) request.get("academic_year"),
                    String.valueOf(request.get("semester")),
                    (String) request.get("course_code"),
                    request.get("process_score") == null ? null : ((Number) request.get("process_score")).floatValue(),
                    request.get("exam_score") == null ? null : ((Number) request.get("exam_score")).floatValue()
            );
            return ResponseEntity.ok(Map.of("message", "Lưu điểm thành công", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @GetMapping("/grades/students/suggestions")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentSuggestions(@RequestParam(required = false) String keyword) {
        return ResponseEntity.ok(Map.of(
                "data", adminAcademicService.searchStudentSuggestions(keyword)
        ));
    }

    @GetMapping("/grades/students/{mssv}/terms")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentTerms(@PathVariable String mssv) {
        try {
            return ResponseEntity.ok(Map.of(
                    "data", adminAcademicService.getStudentTerms(mssv)
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/grades/students/{mssv}/courses")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getStudentCourses(
            @PathVariable String mssv,
            @RequestParam("academic_year") String academicYear,
            @RequestParam("semester") String semester,
            @RequestParam(required = false) String keyword
    ) {
        try {
            return ResponseEntity.ok(Map.of(
                    "data", adminAcademicService.getStudentCoursesByTerm(mssv, academicYear, semester, keyword)
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PostMapping("/grades/preview")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> previewGrades(@RequestParam("course_code") String courseCode,
                                           @RequestParam("file") MultipartFile file) {
        try {
            Map<String, Object> result = adminAcademicService.previewGrades(courseCode, file);
            return ResponseEntity.ok(Map.of("data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/grades/import")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> importGrades(@RequestParam("course_code") String courseCode,
                                          @RequestParam("file") MultipartFile file) {
        try {
            Map<String, Object> result = adminAcademicService.importGrades(courseCode, file);
            return ResponseEntity.ok(Map.of("message", "Import điểm hoàn tất", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    // ── Quản lý tài khoản Admin ──────────────────────────────────────────────

    @GetMapping("/users")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getAdminUsers(@RequestParam(required = false) String keyword) {
        try {
            var list = adminUserService.getAdminUsers(keyword);
            return ResponseEntity.ok(Map.of("total", list.size(), "data", list));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/users")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createAdminUser(@RequestBody Map<String, String> request) {
        try {
            var result = adminUserService.createAdminUser(request.get("username"), request.get("email"));
            return ResponseEntity.ok(Map.of("message", "Tạo tài khoản thành công, mật khẩu đã gửi qua email", "data", result));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/users")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteAdminUsers(@RequestBody Map<String, List<Long>> request) {
        try {
            adminUserService.deleteAdminUsers(request.get("ids"));
            return ResponseEntity.ok(Map.of("message", "Xóa tài khoản thành công"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    // ── Admin Notification Management ────────────────────────────────────────

    @GetMapping("/notifications")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getAdminNotifications(
            @RequestParam(required = false) String content,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String title
    ) {
        try {
            var list = adminNotificationService.getGroupedNotifications(content, type, title);
            return ResponseEntity.ok(Map.of("total", list.size(), "data", list));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @GetMapping("/notifications/detail")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getAdminNotificationDetail(
            @RequestParam String title,
            @RequestParam String content,
            @RequestParam(required = false) String type
    ) {
        try {
            return ResponseEntity.ok(Map.of("data", adminNotificationService.getGroupDetail(title, content, type)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @GetMapping("/notifications/filter-options")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getNotificationFilterOptions() {
        return ResponseEntity.ok(Map.of(
                "types", adminNotificationService.getDistinctTypes(),
                "titles", adminNotificationService.getDistinctTitles()
        ));
    }

    @PostMapping("/notifications/send")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> sendNotifications(@RequestBody AdminSendNotificationRequest request) {
        try {
            int count = adminNotificationService.sendNotifications(request);
            return ResponseEntity.ok(Map.of("message", "Đã gửi thông báo đến " + count + " sinh viên"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/notifications")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteNotificationGroups(@RequestBody AdminDeleteNotificationGroupRequest request) {
        try {
            adminNotificationService.deleteGroups(request);
            return ResponseEntity.ok(Map.of("message", "Đã xóa thông báo"));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi server: " + e.getMessage()));
        }
    }
}
