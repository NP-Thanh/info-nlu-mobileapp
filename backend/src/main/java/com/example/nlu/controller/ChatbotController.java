package com.example.nlu.controller;

import com.example.nlu.dto.request.ChatbotRequest;
import com.example.nlu.dto.response.ChatbotResponse;
import com.example.nlu.service.ChatbotService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/chatbot")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class ChatbotController {

    private final ChatbotService chatbotService;

    @PostMapping("/chat")
    public ResponseEntity<?> chat(
            Authentication authentication,
            @RequestBody ChatbotRequest request) {
        try {
            if (request.getMessage() == null || request.getMessage().isBlank()) {
                return ResponseEntity.badRequest().body(Map.of("message", "Tin nhắn không được để trống"));
            }
            String studentCode = authentication.getName();
            String answer = chatbotService.chat(studentCode, request.getMessage().trim());
            return ResponseEntity.ok(new ChatbotResponse(answer));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("message", "Đã xảy ra lỗi, vui lòng thử lại sau."));
        }
    }
}
