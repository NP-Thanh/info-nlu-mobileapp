package com.example.nlu.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "programs")
@Getter
@Setter
public class Program {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String faculty;
    private String department;
    private String major;
    private String specialization;

    @Column(name = "education_type")
    private String educationType;
}
