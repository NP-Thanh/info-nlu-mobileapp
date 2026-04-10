package com.example.nlu.dto.request;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LoginRequest {
    private String studentId;
    private String password;
}
