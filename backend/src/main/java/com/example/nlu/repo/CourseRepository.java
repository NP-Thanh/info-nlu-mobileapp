package com.example.nlu.repo;

import com.example.nlu.entity.Course;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CourseRepository extends JpaRepository<Course, Long> {
    List<Course> findAllByIsDeletedFalse();

    Optional<Course> findByCourseCodeIgnoreCaseAndIsDeletedFalse(String courseCode);
    boolean existsByCourseCodeIgnoreCaseAndIsDeletedFalse(String courseCode);

    // Dùng để check môn đã bị soft-delete chưa (để restore thay vì tạo mới)
    Optional<Course> findByCourseCodeIgnoreCaseAndIsDeletedTrue(String courseCode);

    // Giữ lại để các quan hệ (Section, Grade...) vẫn có thể load đúng by id
    Optional<Course> findByCourseCodeIgnoreCase(String courseCode);
}
