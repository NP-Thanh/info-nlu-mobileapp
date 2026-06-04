package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class SectionScheduleResponse {
    private Long scheduleId;
    private Integer dayOfWeek;
    private Integer period;
    private String periodStart;
    private String periodEnd;
    private String room;
    private String lecturer;
}
