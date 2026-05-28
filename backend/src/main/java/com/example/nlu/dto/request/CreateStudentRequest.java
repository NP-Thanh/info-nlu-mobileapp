package com.example.nlu.dto.request;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
public class CreateStudentRequest {
    // Student fields (excluding id)
    private String studentCode;
    private String fullName;
    private LocalDate dateOfBirth;
    private String gender;
    private String phone;
    private String cccd;
    private String ethnicity;
    private String religion;
    private String nationality;
    private String placeOfBirth;
    private Integer startYear;
    private Integer endYear;
    private String status;

    // User field
    private String email;

    // StudentProgram
    private Long programId;
    private String className;
}
