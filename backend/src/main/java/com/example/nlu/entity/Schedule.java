package com.example.nlu.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "schedules")
@Getter
@Setter
public class Schedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "section_id")
    private Section section;

    private String room;
    private String lecturer;

    /** 2=Thứ 2, 3=Thứ 3, 4=Thứ 4, 5=Thứ 5, 6=Thứ 6, 7=Thứ 7, 8=Chủ nhật */
    @Column(name = "day_of_week")
    private Integer dayOfWeek;

    /**
     * Ca học: 1=07:00-09:15, 2=09:30-11:45, 3=12:30-14:45, 4=15:00-17:15
     */
    private Integer period;

    /** Soft delete flag */
    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted = false;
}
