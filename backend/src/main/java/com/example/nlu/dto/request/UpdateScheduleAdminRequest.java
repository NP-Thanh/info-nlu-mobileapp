package com.example.nlu.dto.request;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
public class UpdateScheduleAdminRequest {
    private String room;
    private String lecturer;
    private Integer dayOfWeek;
    private Integer period;
    private LocalDate startDate;
    private LocalDate endDate;
    /** Danh sách studentId để set lại (thay thế toàn bộ) */
    private List<Long> studentIds;
}
