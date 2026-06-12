package com.example.nlu.dto.request;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
public class CreateSectionRequest {
    private Long courseId;
    /** Số nhóm: chỉ chứa chữ số, không được để trống */
    private String groupNumber;
    /** Số tổ: chỉ chứa chữ số, không được để trống */
    private String teamNumber;
    private String semester;
    private String academicYear;
    private LocalDate startDate;
    private LocalDate endDate;
}
