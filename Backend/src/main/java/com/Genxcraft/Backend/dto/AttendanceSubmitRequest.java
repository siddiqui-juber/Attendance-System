package com.Genxcraft.Backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceSubmitRequest {
    private Long batchId;
    private Long teacherId;
    private Long subjectId; // Optional
    private String date; // YYYY-MM-DD
    private String time; // HH:MM
    private List<Long> presentStudentIds; // List of primary keys (student table id)
    private String deviceInfo;
}
