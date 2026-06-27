package com.Genxcraft.Backend.service;

import com.Genxcraft.Backend.entity.*;
import com.Genxcraft.Backend.repository.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class BackupRestoreService {

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
    private StudentRepository studentRepository;
    @Autowired
    private AttendanceRepository attendanceRepository;
    @Autowired
    private AttendanceSessionRepository attendanceSessionRepository;
    @Autowired
    private AppSettingsRepository appSettingsRepository;

    @Autowired
    private ObjectMapper objectMapper;

    public String backupData() {
        try {
            Map<String, Object> backupMap = new HashMap<>();
            backupMap.put("branches", branchRepository.findAll());
            backupMap.put("classes", clazzRepository.findAll());
            backupMap.put("batches", batchRepository.findAll());
            backupMap.put("subjects", subjectRepository.findAll());
            backupMap.put("users", userRepository.findAll());
            backupMap.put("students", studentRepository.findAll());
            backupMap.put("attendance", attendanceRepository.findAll());
            backupMap.put("attendanceSessions", attendanceSessionRepository.findAll());
            backupMap.put("appSettings", appSettingsRepository.findAll());

            return objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(backupMap);
        } catch (Exception e) {
            throw new RuntimeException("Error occurred while generating backup", e);
        }
    }

    @Transactional
    public void restoreData(String jsonBackup) {
        try {
            Map<String, List<Map<String, Object>>> backupMap = objectMapper.readValue(jsonBackup, Map.class);

            // 1. Truncate all tables in reverse order of foreign keys
            attendanceRepository.deleteAllInBatch();
            attendanceSessionRepository.deleteAllInBatch();
            studentRepository.deleteAllInBatch();
            userRepository.deleteAllInBatch();
            subjectRepository.deleteAllInBatch();
            batchRepository.deleteAllInBatch();
            clazzRepository.deleteAllInBatch();
            branchRepository.deleteAllInBatch();
            appSettingsRepository.deleteAllInBatch();

            // 2. Deserialize lists and save them back to DB
            // First branches, classes
            List<Branch> branches = objectMapper.convertValue(backupMap.get("branches"),
                    objectMapper.getTypeFactory().constructCollectionType(List.class, Branch.class));
            branchRepository.saveAll(branches);

            List<Clazz> classes = objectMapper.convertValue(backupMap.get("classes"),
                    objectMapper.getTypeFactory().constructCollectionType(List.class, Clazz.class));
            clazzRepository.saveAll(classes);

            // Batches (depends on class)
            List<Batch> batches = objectMapper.convertValue(backupMap.get("batches"),
                    objectMapper.getTypeFactory().constructCollectionType(List.class, Batch.class));
            batchRepository.saveAll(batches);

            // Subjects (depends on class)
            List<Subject> subjects = objectMapper.convertValue(backupMap.get("subjects"),
                    objectMapper.getTypeFactory().constructCollectionType(List.class, Subject.class));
            subjectRepository.saveAll(subjects);

            // Users (depends on branches - ManyToMany)
            List<User> users = objectMapper.convertValue(backupMap.get("users"),
                    objectMapper.getTypeFactory().constructCollectionType(List.class, User.class));
            userRepository.saveAll(users);

            // Students (depends on class and batch)
            List<Student> students = objectMapper.convertValue(backupMap.get("students"),
                    objectMapper.getTypeFactory().constructCollectionType(List.class, Student.class));
            studentRepository.saveAll(students);

            // Attendance
            List<Attendance> attendance = objectMapper.convertValue(backupMap.get("attendance"),
                    objectMapper.getTypeFactory().constructCollectionType(List.class, Attendance.class));
            attendanceRepository.saveAll(attendance);

            // Sessions
            List<AttendanceSession> sessions = objectMapper.convertValue(backupMap.get("attendanceSessions"),
                    objectMapper.getTypeFactory().constructCollectionType(List.class, AttendanceSession.class));
            attendanceSessionRepository.saveAll(sessions);

            // App Settings
            List<AppSettings> appSettings = objectMapper.convertValue(backupMap.get("appSettings"),
                    objectMapper.getTypeFactory().constructCollectionType(List.class, AppSettings.class));
            appSettingsRepository.saveAll(appSettings);

        } catch (Exception e) {
            throw new RuntimeException("Error occurred while restoring data from backup", e);
        }
    }
}
