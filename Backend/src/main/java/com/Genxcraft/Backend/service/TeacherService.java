package com.Genxcraft.Backend.service;

import com.Genxcraft.Backend.dto.AttendanceSubmitRequest;
import com.Genxcraft.Backend.dto.VerifyQrResponse;
import com.Genxcraft.Backend.entity.*;
import com.Genxcraft.Backend.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class TeacherService {

    @Autowired
    private StudentRepository studentRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private BatchRepository batchRepository;
    @Autowired
    private SubjectRepository subjectRepository;
    @Autowired
    private AttendanceRepository attendanceRepository;
    @Autowired
    private AttendanceSessionRepository attendanceSessionRepository;
    @Autowired
    private WhatsAppService whatsAppService;

    public VerifyQrResponse verifyStudentQr(String token, Long batchId) {
        Optional<Student> studentOpt = studentRepository.findByQrCodeToken(token);
        if (studentOpt.isEmpty()) {
            return VerifyQrResponse.builder()
                    .success(false)
                    .message("Invalid QR Code (Student not found)")
                    .build();
        }

        Student student = studentOpt.get();
        if (!student.getBatch().getId().equals(batchId)) {
            return VerifyQrResponse.builder()
                    .success(false)
                    .message("Verification Failed: Student belongs to batch: " + student.getBatch().getName() 
                             + " (Class: " + student.getClazz().getName() + ")")
                    .build();
        }

        // Check if student is already marked present in the DB for today
        LocalDate today = LocalDate.now();
        Optional<Attendance> existingAttendance = attendanceRepository
                .findByStudentIdAndDateAndBatchId(student.getId(), today, batchId);
        
        if (existingAttendance.isPresent() && existingAttendance.get().getStatus() == AttendanceStatus.PRESENT) {
            return VerifyQrResponse.builder()
                    .success(false)
                    .message("This student's attendance has already been recorded.")
                    .id(student.getId())
                    .studentId(student.getStudentId())
                    .name(student.getName())
                    .rollNumber(student.getRollNumber())
                    .className(student.getClazz().getName())
                    .batchName(student.getBatch().getName())
                    .photoUrl(student.getPhotoUrl())
                    .currentStatus("PRESENT")
                    .build();
        }

        return VerifyQrResponse.builder()
                .success(true)
                .message("Student Verified Successfully")
                .id(student.getId())
                .studentId(student.getStudentId())
                .name(student.getName())
                .rollNumber(student.getRollNumber())
                .className(student.getClazz().getName())
                .batchName(student.getBatch().getName())
                .photoUrl(student.getPhotoUrl())
                .currentStatus("NOT_MARKED")
                .build();
    }

    @Transactional
    public void submitAttendance(AttendanceSubmitRequest request) {
        Batch batch = batchRepository.findById(request.getBatchId())
                .orElseThrow(() -> new RuntimeException("Batch not found"));

        User teacher = userRepository.findById(request.getTeacherId())
                .orElseThrow(() -> new RuntimeException("Teacher not found"));

        Subject subject = null;
        if (request.getSubjectId() != null) {
            subject = subjectRepository.findById(request.getSubjectId()).orElse(null);
        }

        LocalDate date = request.getDate() != null ? 
                LocalDate.parse(request.getDate(), DateTimeFormatter.ISO_LOCAL_DATE) : LocalDate.now();
        
        LocalTime time = request.getTime() != null ? 
                LocalTime.parse(request.getTime(), DateTimeFormatter.ofPattern("HH:mm")) : LocalTime.now();

        // 1. Remove previous logs for this batch and date to prevent duplicates or updates
        List<Attendance> oldLogs = attendanceRepository.findByBatchIdAndDate(batch.getId(), date);
        attendanceRepository.deleteAllInBatch(oldLogs);

        // 2. Load all students in the batch
        List<Student> studentsInBatch = studentRepository.findByBatchId(batch.getId());
        List<Attendance> attendanceLogsToSave = new ArrayList<>();

        for (Student student : studentsInBatch) {
            boolean isPresent = request.getPresentStudentIds().contains(student.getId());
            AttendanceStatus status = isPresent ? AttendanceStatus.PRESENT : AttendanceStatus.ABSENT;

            Attendance att = Attendance.builder()
                    .student(student)
                    .teacher(teacher)
                    .batch(batch)
                    .date(date)
                    .time(time)
                    .status(status)
                    .deviceInfo(request.getDeviceInfo())
                    .build();

            attendanceLogsToSave.add(att);
        }

        // Save all records
        attendanceRepository.saveAll(attendanceLogsToSave);

        // 3. Mark session as submitted
        Optional<AttendanceSession> sessionOpt = attendanceSessionRepository.findByBatchIdAndDate(batch.getId(), date);
        AttendanceSession session = sessionOpt.orElse(new AttendanceSession());
        session.setBatch(batch);
        session.setTeacher(teacher);
        session.setSubject(subject);
        session.setDate(date);
        session.setSubmittedAt(LocalDateTime.now());
        attendanceSessionRepository.save(session);

        // 4. Trigger WhatsApp notifications asynchronously/sequentially
        // We will run this in a thread to keep the API fast!
        new Thread(() -> {
            for (Student student : studentsInBatch) {
                boolean isPresent = request.getPresentStudentIds().contains(student.getId());
                if (isPresent) {
                    whatsAppService.sendPresentNotification(student, date, time);
                } else {
                    whatsAppService.sendAbsentNotification(student, date);
                }
            }
        }).start();
    }

    public List<AttendanceSession> getTeacherHistory(Long teacherId) {
        return attendanceSessionRepository.findByTeacherId(teacherId);
    }

    @Transactional
    public Attendance editAttendanceRecord(Long id, AttendanceStatus newStatus, String comment) {
        Attendance attendance = attendanceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Attendance record not found"));

        attendance.setStatus(newStatus);
        // comment can be stored in device info or logs
        if (comment != null && !comment.isEmpty()) {
            attendance.setDeviceInfo(attendance.getDeviceInfo() + " | Edit note: " + comment);
        }
        
        Attendance updated = attendanceRepository.save(attendance);

        // Re-send corrected notification
        if (newStatus == AttendanceStatus.PRESENT) {
            whatsAppService.sendPresentNotification(updated.getStudent(), updated.getDate(), updated.getTime());
        } else {
            whatsAppService.sendAbsentNotification(updated.getStudent(), updated.getDate());
        }

        return updated;
    }

    public List<Attendance> getSessionDetails(Long batchId, String dateStr) {
        LocalDate date = LocalDate.parse(dateStr, DateTimeFormatter.ISO_LOCAL_DATE);
        return attendanceRepository.findByBatchIdAndDate(batchId, date);
    }
}
