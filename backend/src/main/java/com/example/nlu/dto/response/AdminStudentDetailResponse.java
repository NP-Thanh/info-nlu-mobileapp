package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AdminStudentDetailResponse {
    private Long id;
    private String studentCode;
    private String fullName;
    private String gender;
    private String dateOfBirth;
    private String phone;
    private String email;
    private String status;
    private Integer startYear;
    private Integer endYear;
    private String cccd;
    private String ethnicity;
    private String religion;
    private String nationality;
    private String placeOfBirth;

    private Long programId;
    private String className;
    private String faculty;
    private String major;
    private String specialization;
    private String educationType;
}
