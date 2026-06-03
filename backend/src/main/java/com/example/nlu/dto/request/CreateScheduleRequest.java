package com.example.nlu.dto.request;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
public class CreateScheduleRequest {
    /** ID của course */
    private Long courseId;
    /** LT hay TH */
    private Boolean isLab;
    /** Học kỳ: "1", "2", "3" */
    private String semester;
    /** Năm học: "2023-2024" */
    private String academicYear;
    /** Ngày bắt đầu */
    private LocalDate startDate;
    /** Ngày kết thúc */
    private LocalDate endDate;
    /** Phòng học */
    private String room;
    /** Giảng viên */
    private String lecturer;
    /** Thứ trong tuần: 2-8 */
    private Integer dayOfWeek;
    /** Ca học: 1-4 */
    private Integer period;
}
