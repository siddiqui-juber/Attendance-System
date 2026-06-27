package com.Genxcraft.Backend.controller;

import com.Genxcraft.Backend.dto.AttendanceSubmitRequest;
import com.Genxcraft.Backend.dto.VerifyQrResponse;
import com.Genxcraft.Backend.entity.Attendance;
import com.Genxcraft.Backend.entity.AttendanceSession;
import com.Genxcraft.Backend.entity.AttendanceStatus;
import com.Genxcraft.Backend.service.TeacherService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/teacher")
public class TeacherController {

    @Autowired
    private TeacherService teacherService;

    @PostMapping("/attendance/verify-qr")
    public ResponseEntity<VerifyQrResponse> verifyQr(@RequestParam String token, @RequestParam Long batchId) {
        return ResponseEntity.ok(teacherService.verifyStudentQr(token, batchId));
    }

    @PostMapping("/attendance/submit")
    public ResponseEntity<String> submitAttendance(@RequestBody AttendanceSubmitRequest request) {
        teacherService.submitAttendance(request);
        return ResponseEntity.ok("Attendance submitted and notifications sent");
    }

    @GetMapping("/attendance/history")
    public ResponseEntity<List<AttendanceSession>> getHistory(@RequestParam Long teacherId) {
        return ResponseEntity.ok(teacherService.getTeacherHistory(teacherId));
    }

    @GetMapping("/attendance/session-details")
    public ResponseEntity<List<Attendance>> getSessionDetails(@RequestParam Long batchId, @RequestParam String date) {
        return ResponseEntity.ok(teacherService.getSessionDetails(batchId, date));
    }

    @PutMapping("/attendance/{id}")
    public ResponseEntity<Attendance> editAttendance(
            @PathVariable Long id,
            @RequestParam AttendanceStatus status,
            @RequestParam(required = false) String comment) {
        return ResponseEntity.ok(teacherService.editAttendanceRecord(id, status, comment));
    }
}
