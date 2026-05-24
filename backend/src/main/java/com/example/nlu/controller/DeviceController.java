package com.example.nlu.controller;

import com.example.nlu.dto.request.RegisterDeviceRequest;
import com.example.nlu.service.DeviceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.Map;

@RestController
@RequestMapping("/api/devices")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class DeviceController {

    private final DeviceService deviceService;

    @PostMapping("/register")
    public ResponseEntity<?> registerDevice(Principal principal, @RequestBody RegisterDeviceRequest request) {
        if (principal == null) {
            return ResponseEntity.status(401).body(Map.of("message", "Bạn chưa đăng nhập"));
        }
        try {
            deviceService.registerDevice(
                    principal.getName(),
                    request.getDeviceToken(),
                    request.getDeviceType());
            return ResponseEntity.ok(Map.of("message", "Đã đăng ký thiết bị"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @DeleteMapping
    public ResponseEntity<?> unregisterDevice(Principal principal, @RequestBody RegisterDeviceRequest request) {
        if (principal == null) {
            return ResponseEntity.status(401).body(Map.of("message", "Bạn chưa đăng nhập"));
        }
        try {
            deviceService.unregisterDevice(principal.getName(), request.getDeviceToken());
            return ResponseEntity.ok(Map.of("message", "Đã hủy đăng ký thiết bị"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }
}
