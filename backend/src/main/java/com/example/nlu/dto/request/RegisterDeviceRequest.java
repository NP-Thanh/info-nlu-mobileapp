package com.example.nlu.dto.request;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class RegisterDeviceRequest {
    private String deviceToken;
    /** android | ios */
    private String deviceType;
}
