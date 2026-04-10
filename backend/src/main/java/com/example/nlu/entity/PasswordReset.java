package com.example.nlu.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "password_resets")
@Getter
@Setter
public class PasswordReset {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "student_code")
    private String studentCode;

    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    @Column(name = "new_password")
    private String newPassword;

    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
