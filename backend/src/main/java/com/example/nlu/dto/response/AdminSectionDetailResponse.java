package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class AdminSectionDetailResponse {
    private Long sectionId;
    private Long courseId;
    private String courseCode;
    private String courseName;
    private Integer credits;
    private Boolean isLab;
    private String semester;
    private String academicYear;
    private String startDate;
    private String endDate;
    private List<SectionScheduleResponse> schedules;
    private List<StudentInScheduleResponse> students;
}
