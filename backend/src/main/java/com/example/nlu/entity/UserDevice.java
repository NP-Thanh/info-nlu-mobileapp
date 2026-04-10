package com.example.nlu.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "user_devices")
@Getter
@Setter
public class UserDevice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "device_token", columnDefinition = "TEXT")
    private String deviceToken;

    @Column(name = "device_type")
    private String deviceType;

    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
