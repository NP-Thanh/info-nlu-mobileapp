package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class GradeItemResponse {
    private String courseCode;
    private String courseName;
    private Integer credits;
    private Float processScore;
    private Float examScore;
    private Float finalScore10;
    private Float finalScore4;
    private String result;
}
