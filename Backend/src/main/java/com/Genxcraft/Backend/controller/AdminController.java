package com.Genxcraft.Backend.controller;

import com.Genxcraft.Backend.dto.DashboardStatsResponse;
import com.Genxcraft.Backend.dto.StudentRegisterRequest;
import com.Genxcraft.Backend.dto.TeacherRegisterRequest;
import com.Genxcraft.Backend.entity.*;
import com.Genxcraft.Backend.service.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    @Autowired
    private AdminService adminService;
    @Autowired
    private QrCodeService qrCodeService;
    @Autowired
    private CloudinaryService cloudinaryService;
    @Autowired
    private SettingsService settingsService;
    @Autowired
    private BackupRestoreService backupRestoreService;

    // --- Branches ---
    @PostMapping("/branches")
    public ResponseEntity<Branch> createBranch(@RequestBody Branch branch) {
        return ResponseEntity.ok(adminService.createBranch(branch));
    }

    @GetMapping("/branches")
    public ResponseEntity<List<Branch>> getAllBranches() {
        return ResponseEntity.ok(adminService.getAllBranches());
    }

    @DeleteMapping("/branches/{id}")
    public ResponseEntity<Void> deleteBranch(@PathVariable Long id) {
        adminService.deleteBranch(id);
        return ResponseEntity.ok().build();
    }

    // --- Classes ---
    @PostMapping("/classes")
    public ResponseEntity<Clazz> createClass(@RequestBody Clazz clazz) {
        return ResponseEntity.ok(adminService.createClass(clazz));
    }

    @GetMapping("/classes")
    public ResponseEntity<List<Clazz>> getAllClasses() {
        return ResponseEntity.ok(adminService.getAllClasses());
    }

    @DeleteMapping("/classes/{id}")
    public ResponseEntity<Void> deleteClass(@PathVariable Long id) {
        adminService.deleteClass(id);
        return ResponseEntity.ok().build();
    }

    // --- Batches ---
    @PostMapping("/batches")
    public ResponseEntity<Batch> createBatch(@RequestBody Batch batch) {
        return ResponseEntity.ok(adminService.createBatch(batch));
    }

    @GetMapping("/batches")
    public ResponseEntity<List<Batch>> getAllBatches() {
        return ResponseEntity.ok(adminService.getAllBatches());
    }

    @GetMapping("/classes/{classId}/batches")
    public ResponseEntity<List<Batch>> getBatchesByClass(@PathVariable Long classId) {
        return ResponseEntity.ok(adminService.getBatchesByClass(classId));
    }

    @DeleteMapping("/batches/{id}")
    public ResponseEntity<Void> deleteBatch(@PathVariable Long id) {
        adminService.deleteBatch(id);
        return ResponseEntity.ok().build();
    }

    // --- Subjects ---
    @PostMapping("/subjects")
    public ResponseEntity<Subject> createSubject(@RequestBody Subject subject) {
        return ResponseEntity.ok(adminService.createSubject(subject));
    }

    @GetMapping("/subjects")
    public ResponseEntity<List<Subject>> getAllSubjects() {
        return ResponseEntity.ok(adminService.getAllSubjects());
    }

    @GetMapping("/classes/{classId}/subjects")
    public ResponseEntity<List<Subject>> getSubjectsByClass(@PathVariable Long classId) {
        return ResponseEntity.ok(adminService.getSubjectsByClass(classId));
    }

    @DeleteMapping("/subjects/{id}")
    public ResponseEntity<Void> deleteSubject(@PathVariable Long id) {
        adminService.deleteSubject(id);
        return ResponseEntity.ok().build();
    }

    // --- Teachers ---
    @PostMapping("/teachers")
    public ResponseEntity<User> registerTeacher(@RequestBody TeacherRegisterRequest request) {
        return ResponseEntity.ok(adminService.registerTeacher(request));
    }

    @GetMapping("/teachers")
    public ResponseEntity<List<User>> getAllTeachers() {
        return ResponseEntity.ok(adminService.getAllTeachers());
    }

    @PutMapping("/teachers/{id}")
    public ResponseEntity<User> updateTeacher(@PathVariable Long id, @RequestBody TeacherRegisterRequest request) {
        return ResponseEntity.ok(adminService.updateTeacher(id, request));
    }

    @DeleteMapping("/teachers/{id}")
    public ResponseEntity<Void> deleteTeacher(@PathVariable Long id) {
        adminService.deleteTeacher(id);
        return ResponseEntity.ok().build();
    }

    // --- Students ---
    @PostMapping("/students")
    public ResponseEntity<Student> registerStudent(@RequestBody StudentRegisterRequest request) {
        return ResponseEntity.ok(adminService.registerStudent(request));
    }

    @GetMapping("/students")
    public ResponseEntity<List<Student>> getAllStudents() {
        return ResponseEntity.ok(adminService.getAllStudents());
    }

    @GetMapping("/students/{id}")
    public ResponseEntity<Student> getStudent(@PathVariable Long id) {
        return ResponseEntity.ok(adminService.getStudent(id));
    }

    @PutMapping("/students/{id}")
    public ResponseEntity<Student> updateStudent(@PathVariable Long id, @RequestBody StudentRegisterRequest request) {
        return ResponseEntity.ok(adminService.updateStudent(id, request));
    }

    @DeleteMapping("/students/{id}")
    public ResponseEntity<Void> deleteStudent(@PathVariable Long id) {
        adminService.deleteStudent(id);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/students/{id}/regenerate-qr")
    public ResponseEntity<Student> regenerateQrCode(@PathVariable Long id) {
        return ResponseEntity.ok(adminService.regenerateQrCode(id));
    }

    @PostMapping("/students/upload-photo")
    public ResponseEntity<Map<String, String>> uploadPhoto(@RequestParam("file") MultipartFile file) throws IOException {
        String url = cloudinaryService.uploadImage(file);
        return ResponseEntity.ok(Map.of("url", url));
    }

    @GetMapping(value = "/students/{id}/qr-code", produces = MediaType.IMAGE_PNG_VALUE)
    public ResponseEntity<byte[]> getStudentQrCode(@PathVariable Long id) {
        Student student = adminService.getStudent(id);
        byte[] qrBytes = qrCodeService.generateQrCodeImage(student.getQrCodeToken(), 300, 300);
        return ResponseEntity.ok(qrBytes);
    }

    // --- Dashboard ---
    @GetMapping("/dashboard/stats")
    public ResponseEntity<DashboardStatsResponse> getDashboardStats() {
        return ResponseEntity.ok(adminService.getDashboardStats());
    }

    // --- Settings ---
    @GetMapping("/settings")
    public ResponseEntity<Map<String, String>> getAllSettings() {
        return ResponseEntity.ok(settingsService.getAllSettings());
    }

    @PostMapping("/settings")
    public ResponseEntity<Void> updateSetting(@RequestParam String key, @RequestParam String value) {
        settingsService.updateSetting(key, value);
        return ResponseEntity.ok().build();
    }

    // --- Backup & Restore ---
    @GetMapping("/backup")
    public ResponseEntity<byte[]> downloadBackup() {
        String backupJson = backupRestoreService.backupData();
        byte[] backupBytes = backupJson.getBytes();
        
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"backup_" + LocalDate.now() + ".json\"")
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(backupBytes);
    }

    @PostMapping("/restore")
    public ResponseEntity<String> restoreBackup(@RequestParam("file") MultipartFile file) {
        try {
            String content = new String(file.getBytes());
            backupRestoreService.restoreData(content);
            return ResponseEntity.ok("Database restored successfully");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to restore backup: " + e.getMessage());
        }
    }
}
