package com.example.nlu.repo;

import com.example.nlu.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findByUser_IdAndIsDeletedFalseOrderByCreatedAtDesc(Long userId);

    List<Notification> findByUser_IdAndIsReadFalseAndIsDeletedFalseOrderByCreatedAtDesc(Long userId);

    Optional<Notification> findByIdAndUser_IdAndIsDeletedFalse(Long id, Long userId);

    List<Notification> findByIdInAndUser_IdAndIsDeletedFalse(List<Long> ids, Long userId);

    // ── Admin queries ──────────────────────────────────────────────────────────

    /**
     * Lấy 1 đại diện cho mỗi nhóm (title + content + type) – chọn bản ghi có id nhỏ nhất.
     * Lọc theo content (realtime search), type, title.
     */
    @Query("""
        SELECT n FROM Notification n
        WHERE n.isDeleted = false
          AND n.id = (
              SELECT MIN(n2.id) FROM Notification n2
              WHERE n2.isDeleted = false
                AND n2.title = n.title
                AND n2.content = n.content
                AND (n2.type = n.type OR (n2.type IS NULL AND n.type IS NULL))
          )
          AND (:content IS NULL OR :content = '' OR LOWER(n.content) LIKE LOWER(CONCAT('%', :content, '%')))
          AND (:type    IS NULL OR :type    = '' OR n.type    = :type)
          AND (:title   IS NULL OR :title   = '' OR n.title   = :title)
        ORDER BY n.createdAt DESC
        """)
    List<Notification> findGroupedNotifications(
            @Param("content") String content,
            @Param("type") String type,
            @Param("title") String title
    );

    /** Đếm số sinh viên nhận thông báo cùng nhóm (title + content + type). */
    @Query("""
        SELECT COUNT(n) FROM Notification n
        WHERE n.isDeleted = false
          AND n.title = :title
          AND n.content = :content
          AND (:type IS NULL AND n.type IS NULL OR n.type = :type)
        """)
    long countByGroup(
            @Param("title") String title,
            @Param("content") String content,
            @Param("type") String type
    );

    /** Lấy danh sách notifications cùng nhóm kèm thông tin sinh viên. */
    @Query("""
        SELECT n FROM Notification n
        JOIN FETCH n.user u
        WHERE n.isDeleted = false
          AND n.title = :title
          AND n.content = :content
          AND (:type IS NULL AND n.type IS NULL OR n.type = :type)
        ORDER BY n.createdAt DESC
        """)
    List<Notification> findByGroup(
            @Param("title") String title,
            @Param("content") String content,
            @Param("type") String type
    );

    /** Lấy tất cả type hiện có (không null, không trùng). */
    @Query("SELECT DISTINCT n.type FROM Notification n WHERE n.isDeleted = false AND n.type IS NOT NULL ORDER BY n.type")
    List<String> findDistinctTypes();

    /** Lấy tất cả title hiện có (không trùng). */
    @Query("SELECT DISTINCT n.title FROM Notification n WHERE n.isDeleted = false AND n.title IS NOT NULL ORDER BY n.title")
    List<String> findDistinctTitles();

    /** Soft-delete tất cả notifications cùng nhóm. */
    @Query("""
        SELECT n FROM Notification n
        WHERE n.isDeleted = false
          AND n.title = :title
          AND n.content = :content
          AND (:type IS NULL AND n.type IS NULL OR n.type = :type)
        """)
    List<Notification> findAllByGroupForDelete(
            @Param("title") String title,
            @Param("content") String content,
            @Param("type") String type
    );
}
