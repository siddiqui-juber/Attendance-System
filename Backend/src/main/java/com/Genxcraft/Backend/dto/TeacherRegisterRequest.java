package com.Genxcraft.Backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Set;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class TeacherRegisterRequest {
    private String name;
    private String username;
    private String email;
    private String password;
    private Set<Long> branchIds;
}
