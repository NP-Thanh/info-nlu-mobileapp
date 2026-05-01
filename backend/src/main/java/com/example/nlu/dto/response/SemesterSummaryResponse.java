package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class SemesterSummaryResponse {
    private String semester;
    private String academicYear;
    private Float gpa10;
    private Float gpa4;
    private Float cumulativeGpa10;
    private Float cumulativeGpa4;
}
