package com.example.nlu.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "semester_summary")
@Getter
@Setter
public class SemesterSummary {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "student_id")
    private Student student;

    private String semester;

    @Column(name = "academic_year")
    private String academicYear;

    @Column(name = "gpa_10")
    private Float gpa10;

    @Column(name = "gpa_4")
    private Float gpa4;

    @Column(name = "cumulative_gpa_10")
    private Float cumulativeGpa10;

    @Column(name = "cumulative_gpa_4")
    private Float cumulativeGpa4;
}
