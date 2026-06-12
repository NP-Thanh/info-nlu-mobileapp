package com.example.nlu.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "grades",
       uniqueConstraints = @UniqueConstraint(columnNames = "enrollment_id"))
@Getter
@Setter
public class Grade {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Mỗi bản ghi điểm gắn với một enrollment (student + section) cụ thể */
    @OneToOne
    @JoinColumn(name = "enrollment_id", nullable = false)
    private Enrollment enrollment;

    @Column(name = "process_score")
    private Float processScore;

    @Column(name = "exam_score")
    private Float examScore;

    @Column(name = "final_score_10")
    private Float finalScore10;

    @Column(name = "final_score_4")
    private Float finalScore4;

    private String result;
}
