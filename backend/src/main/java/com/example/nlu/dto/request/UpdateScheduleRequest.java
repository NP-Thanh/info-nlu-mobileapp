package com.example.nlu.dto.request;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateScheduleRequest {
    private String room;
    private String lecturer;
    private Integer dayOfWeek;
    private Integer period;
}
