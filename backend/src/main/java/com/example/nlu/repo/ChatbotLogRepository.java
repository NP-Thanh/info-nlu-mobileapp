package com.example.nlu.repo;

import com.example.nlu.entity.ChatbotLog;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ChatbotLogRepository extends JpaRepository<ChatbotLog, Long> {
}
