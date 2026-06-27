package com.Genxcraft.Backend.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VerifyQrResponse {
    private boolean success;
    private String message;
    private Long id; // DB PK
    private String studentId; // e.g. STU001
    private String name;
    private String rollNumber;
    private String className;
    private String batchName;
    private String photoUrl;
    private String currentStatus;
}
