package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AdminScheduleListResponse {
    private Long scheduleId;
    private Long sectionId;
    private Long courseId;
    private String courseCode;
    private String courseName;
    private Integer credits;
    private Boolean isLab;
    private String semester;
    private String academicYear;
    private String room;
    private String lecturer;
    private Integer dayOfWeek;
    private Integer period;
    private String periodStart;
    private String periodEnd;
    private Integer studentCount;
}
