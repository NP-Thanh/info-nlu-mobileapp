package com.example.nlu.dto.request;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ForgotPasswordRequest {
    private String studentCode;
    private String dateOfBirth; // format: dd/MM/yyyy
}
