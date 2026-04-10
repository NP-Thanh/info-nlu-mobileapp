package com.example.nlu.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class LoginResponse {
    private String token;
    private String studentCode;
    private String fullName;
    private String role;
}
