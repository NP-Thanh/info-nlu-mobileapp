package com.example.nlu.repo;

import com.example.nlu.entity.Schedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ScheduleRepository extends JpaRepository<Schedule, Long> {

    @Query("SELECT s FROM Schedule s " +
           "JOIN FETCH s.enrollment e " +
           "JOIN FETCH e.course c " +
           "WHERE e.id IN :enrollmentIds")
    List<Schedule> findByEnrollmentIds(@Param("enrollmentIds") List<Long> enrollmentIds);
}
