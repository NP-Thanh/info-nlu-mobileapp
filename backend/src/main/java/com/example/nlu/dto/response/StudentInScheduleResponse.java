package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class StudentInScheduleResponse {
    private Long studentId;
    private String studentCode;
    private String fullName;
}
