package com.example.nlu.dto.request;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateSectionScheduleRequest {
    private Integer dayOfWeek;
    private Integer period;
    private String room;
    private String lecturer;
    private Boolean isLab;
}
