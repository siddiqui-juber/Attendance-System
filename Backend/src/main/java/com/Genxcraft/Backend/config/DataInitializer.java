package com.Genxcraft.Backend.config;

import com.Genxcraft.Backend.entity.*;
import com.Genxcraft.Backend.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.HashSet;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BranchRepository branchRepository;

    @Autowired
    private ClazzRepository clazzRepository;

    @Autowired
    private BatchRepository batchRepository;

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        // 1. Create default branch if empty
        Branch branch = branchRepository.findByName("Main Branch")
                .orElseGet(() -> branchRepository.save(Branch.builder().name("Main Branch").build()));

        // 2. Create default Admin if empty
        if (!userRepository.existsByUsername("admin")) {
            User admin = User.builder()
                    .name("Administrator")
                    .username("admin")
                    .email("admin@attendance.com")
                    .password(passwordEncoder.encode("admin123"))
                    .role(Role.ADMIN)
                    .active(true)
                    .branches(new HashSet<>(Collections.singletonList(branch)))
                    .build();
            userRepository.save(admin);
        }

        // 3. Create default teacher if empty
        if (!userRepository.existsByUsername("teacher")) {
            User teacher = User.builder()
                    .name("John Doe")
                    .username("teacher")
                    .email("teacher@attendance.com")
                    .password(passwordEncoder.encode("teacher123"))
                    .role(Role.TEACHER)
                    .active(true)
                    .branches(new HashSet<>(Collections.singletonList(branch)))
                    .build();
            userRepository.save(teacher);
        }

        // 4. Create default class if empty
        Clazz clazz = clazzRepository.findByName("10th Standard")
                .orElseGet(() -> clazzRepository.save(Clazz.builder().name("10th Standard").build()));

        // 5. Create default batch if empty
        if (batchRepository.findByClazzId(clazz.getId()).isEmpty()) {
            batchRepository.save(Batch.builder()
                    .name("Batch A")
                    .clazz(clazz)
                    .build());
            batchRepository.save(Batch.builder()
                    .name("Batch B")
                    .clazz(clazz)
                    .build());
        }

        // 6. Create default subjects if empty
        if (subjectRepository.findByClazzId(clazz.getId()).isEmpty()) {
            subjectRepository.save(Subject.builder()
                    .name("Physics")
                    .clazz(clazz)
                    .build());
            subjectRepository.save(Subject.builder()
                    .name("Chemistry")
                    .clazz(clazz)
                    .build());
            subjectRepository.save(Subject.builder()
                    .name("Mathematics")
                    .clazz(clazz)
                    .build());
        }
    }
}
