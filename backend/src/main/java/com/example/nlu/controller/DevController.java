package com.example.nlu.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Controller chỉ dùng để debug/dev — xóa trước khi production
 */
@RestController
@RequestMapping("/api/dev")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class DevController {

    private final PasswordEncoder passwordEncoder;

    // GET /api/dev/hash?raw=123456  → trả về BCrypt hash
    @GetMapping("/hash")
    public Map<String, String> hash(@RequestParam String raw) {
        return Map.of("hash", passwordEncoder.encode(raw));
    }

    // GET /api/dev/verify?raw=123456&hash=...  → kiểm tra match
    @GetMapping("/verify")
    public Map<String, Object> verify(@RequestParam String raw, @RequestParam String hash) {
        boolean matches = passwordEncoder.matches(raw, hash);
        return Map.of("matches", matches);
    }
}
