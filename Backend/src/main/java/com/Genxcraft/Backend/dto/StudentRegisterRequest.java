package com.Genxcraft.Backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class StudentRegisterRequest {
    private String studentId; // If empty, we will auto-generate
    private String name;
    private String rollNumber;
    private Long classId;
    private Long batchId;
    private String parentName;
    private String parentMobile;
    private String parentWhatsApp;
    private String address;
    private String photoUrl;
}
