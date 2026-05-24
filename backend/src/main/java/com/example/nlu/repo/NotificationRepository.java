package com.example.nlu.repo;

import com.example.nlu.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findByUser_IdAndIsDeletedFalseOrderByCreatedAtDesc(Long userId);

    List<Notification> findByUser_IdAndIsReadFalseAndIsDeletedFalseOrderByCreatedAtDesc(Long userId);

    Optional<Notification> findByIdAndUser_IdAndIsDeletedFalse(Long id, Long userId);

    List<Notification> findByIdInAndUser_IdAndIsDeletedFalse(List<Long> ids, Long userId);
}
