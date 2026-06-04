package com.example.nlu.service;

import com.example.nlu.dto.response.ChatbotLogResponse;
import com.example.nlu.entity.ChatbotLog;
import com.example.nlu.repo.ChatbotLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AdminChatbotService {

    private final ChatbotLogRepository chatbotLogRepository;

    public List<ChatbotLogResponse> getLogs(String keyword, Boolean flagged) {
        String kw = (keyword == null || keyword.isBlank()) ? null : keyword.trim();
        return chatbotLogRepository.findAllByKeywordAndFlag(kw, flagged)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public ChatbotLogResponse getLogDetail(Long id) {
        ChatbotLog log = chatbotLogRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy log chat #" + id));
        return toResponse(log);
    }

    public void flagLogs(List<Long> ids, boolean flagged) {
        List<ChatbotLog> logs = chatbotLogRepository.findAllById(ids);
        if (logs.isEmpty()) throw new IllegalArgumentException("Không tìm thấy log chat nào");
        logs.forEach(l -> l.setIsFlagged(flagged));
        chatbotLogRepository.saveAll(logs);
    }

    public void deleteLogs(List<Long> ids) {
        if (ids == null || ids.isEmpty()) throw new IllegalArgumentException("Danh sách ID không được rỗng");
        chatbotLogRepository.deleteAllById(ids);
    }

    private ChatbotLogResponse toResponse(ChatbotLog c) {
        String code = c.getStudent() != null ? c.getStudent().getStudentCode() : null;
        String name = c.getStudent() != null ? c.getStudent().getFullName() : null;
        return ChatbotLogResponse.builder()
                .id(c.getId())
                .question(c.getQuestion())
                .answer(c.getAnswer())
                .createdAt(c.getCreatedAt() != null ? c.getCreatedAt().toString() : null)
                .isFlagged(c.getIsFlagged())
                .studentCode(code)
                .studentName(name)
                .build();
    }
}
