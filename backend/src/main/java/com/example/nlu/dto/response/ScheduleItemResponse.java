package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ScheduleItemResponse {
    private Long scheduleId;
    private String courseName;
    private String courseCode;
    private Integer credits;
    private String lecturer;
    private String room;
    private Integer dayOfWeek;
    /** Ca học 1-4 */
    private Integer period;
    private String periodStart;
    private String periodEnd;
    private String enrollmentStartDate;
    private String enrollmentEndDate;
}
