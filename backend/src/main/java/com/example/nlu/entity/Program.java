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

    private String faculty; //khoa
    private String major; //ngành
    private String specialization; //chuyên ngành

    @Column(name = "education_type")
    private String educationType;
}
