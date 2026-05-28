package com.example.nlu.dto.request;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
public class UpdateStudentRequest {
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
    private String email;

    private Long programId;
    private String className;
}
