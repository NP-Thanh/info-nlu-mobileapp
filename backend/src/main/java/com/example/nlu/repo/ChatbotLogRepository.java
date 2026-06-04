package com.example.nlu.repo;

import com.example.nlu.entity.ChatbotLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ChatbotLogRepository extends JpaRepository<ChatbotLog, Long> {

    @Query("SELECT c FROM ChatbotLog c WHERE c.student.studentCode = :studentCode ORDER BY c.createdAt ASC")
    List<ChatbotLog> findByStudentCodeOrderByCreatedAt(@Param("studentCode") String studentCode);

    @Query("""
        SELECT c FROM ChatbotLog c
        WHERE (:keyword IS NULL OR :keyword = ''
               OR LOWER(c.student.studentCode) LIKE LOWER(CONCAT('%', :keyword, '%'))
               OR LOWER(c.student.fullName)    LIKE LOWER(CONCAT('%', :keyword, '%')))
          AND (:flagged IS NULL OR c.isFlagged = :flagged)
        ORDER BY c.createdAt DESC
    """)
    List<ChatbotLog> findAllByKeywordAndFlag(
        @Param("keyword") String keyword,
        @Param("flagged") Boolean flagged
    );
}
