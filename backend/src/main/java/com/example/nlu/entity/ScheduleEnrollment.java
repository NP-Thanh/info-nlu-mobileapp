package com.example.nlu.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "schedule_enrollments")
@Getter
@Setter
public class ScheduleEnrollment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "schedule_id")
    private Schedule schedule;

    @ManyToOne
    @JoinColumn(name = "student_id")
    private Student student;
}
