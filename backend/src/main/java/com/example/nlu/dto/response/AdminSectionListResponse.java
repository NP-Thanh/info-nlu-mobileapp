package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AdminSectionListResponse {
    private Long sectionId;
    private Long courseId;
    private String courseCode;
    private String courseName;
    private Integer credits;
    private Integer groupNumber;
    private Integer teamNumber;
    private String semester;
    private String academicYear;
    private String startDate;
    private String endDate;
    private Integer studentCount;
    private Integer scheduleCount;
}
