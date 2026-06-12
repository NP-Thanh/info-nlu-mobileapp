package com.example.nlu.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

/**
 * Nhóm học phần (section): một lớp học của môn trong một học kỳ.
 * Một section có thể có nhiều sinh viên (qua bảng enrollments).
 */
@Entity
@Table(name = "sections")
@Getter
@Setter
public class Section {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

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

    /** Số nhóm (ví dụ: 1, 2, 3) */
    @Column(name = "group_number", nullable = false, columnDefinition = "INT DEFAULT 1")
    private Integer groupNumber = 1;

    /** Số tổ (ví dụ: 1, 2, 3) */
    @Column(name = "team_number", nullable = false, columnDefinition = "INT DEFAULT 1")
    private Integer teamNumber = 1;

    /** Soft delete */
    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted = false;
}
