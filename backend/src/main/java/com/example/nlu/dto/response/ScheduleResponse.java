package com.example.nlu.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class ScheduleResponse {
    private String semester;
    private String academicYear;
    private String startDate;
    private String endDate;
    private List<ScheduleItemResponse> items;
}
