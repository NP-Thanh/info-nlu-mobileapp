package com.example.nlu.controller;

import com.example.nlu.dto.response.ScheduleResponse;
import com.example.nlu.service.ScheduleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/schedule")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class ScheduleController {

    private final ScheduleService scheduleService;

    /** Lấy TKB học kỳ mới nhất */
    @GetMapping("/latest")
    public ResponseEntity<?> getLatest(Authentication auth) {
        try {
            ScheduleResponse res = scheduleService.getLatestSchedule(auth.getName());
            return ResponseEntity.ok(res);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("message", e.getMessage()));
        }
    }

    /** Lấy TKB theo học kỳ cụ thể */
    @GetMapping
    public ResponseEntity<?> getSchedule(
            Authentication auth,
            @RequestParam String academicYear,
            @RequestParam String semester) {
        try {
            ScheduleResponse res = scheduleService.getSchedule(auth.getName(), academicYear, semester);
            return ResponseEntity.ok(res);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("message", e.getMessage()));
        }
    }

    /** Lấy danh sách tất cả học kỳ */
    @GetMapping("/all")
    public ResponseEntity<?> getAllSemesters(Authentication auth) {
        try {
            List<ScheduleResponse> res = scheduleService.getAllSemesters(auth.getName());
            return ResponseEntity.ok(res);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("message", e.getMessage()));
        }
    }
}
