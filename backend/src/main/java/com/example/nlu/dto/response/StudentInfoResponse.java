package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class StudentInfoResponse {
    // ID card
    private String studentCode;
    private String fullName;
    private String status;

    // Thông tin sinh viên
    private String dateOfBirth;
    private String gender;
    private String phone;
    private String idCard;
    private String email;

    // Hành chính
    private String birthPlace;
    private String ethnicity;
    private String religion;
    private String nationality;

    // Thông tin khóa học
    private String major;
    private String specialization;
    private String classCode;
    private String faculty;
    private String academicYear;
    private String degreeType;
}
