package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AdminStudentResponse {
    private Long id;
    private String studentCode;
    private String fullName;
    private String gender;
    private String dateOfBirth;
    private String phone;
    private String email;
    private String status;
    private Integer startYear;

    // StudentProgram
    private String className;
    private String faculty;
    private String major;
    private String specialization;
}
