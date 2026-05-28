package com.example.nlu.dto.request;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class StudentIdsRequest {
    private List<Long> ids;
}
