package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class GradeResponse {
    private String semester;
    private String academicYear;
    private List<GradeItemResponse> grades;
}
