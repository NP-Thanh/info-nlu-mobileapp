package com.example.nlu.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "enrollments")
@Getter
@Setter
public class Enrollment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "student_id")
    private Student student;

    @ManyToOne
    @JoinColumn(name = "course_id")
    private Course course;

    /** Học kỳ: "1", "2", "3" */
    private String semester;

    /** Năm học: "2023-2024" */
    @Column(name = "academic_year")
    private String academicYear;

    /** Ngày bắt đầu học kỳ */
    @Column(name = "start_date")
    private LocalDate startDate;

    /** Ngày kết thúc học kỳ */
    @Column(name = "end_date")
    private LocalDate endDate;

    private Integer attempt;

    @Column(name = "is_lab")
    private Boolean isLab = false;
}
