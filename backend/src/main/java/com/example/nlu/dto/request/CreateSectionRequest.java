package com.example.nlu.dto.request;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
public class CreateSectionRequest {
    private Long courseId;
    private Boolean isLab;
    private String semester;
    private String academicYear;
    private LocalDate startDate;
    private LocalDate endDate;
}
