package com.Genxcraft.Backend.controller;

import com.Genxcraft.Backend.entity.Attendance;
import com.Genxcraft.Backend.repository.AttendanceRepository;
import com.Genxcraft.Backend.service.ReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/reports")
public class ReportController {

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Autowired
    private ReportService reportService;

    private List<Attendance> getFilteredLogs(Long studentId, Long batchId, Long classId, String startDateStr, String endDateStr) {
        LocalDate start = startDateStr != null ? LocalDate.parse(startDateStr) : LocalDate.now().minusMonths(1);
        LocalDate end = endDateStr != null ? LocalDate.parse(endDateStr) : LocalDate.now();

        List<Attendance> logs;
        if (studentId != null) {
            logs = attendanceRepository.findByStudentIdAndDateBetween(studentId, start, end);
        } else if (batchId != null) {
            logs = attendanceRepository.findByBatchIdAndDateBetween(batchId, start, end);
        } else {
            logs = attendanceRepository.findByDateBetween(start, end);
        }

        if (classId != null) {
            logs = logs.stream()
                    .filter(log -> log.getStudent().getClazz().getId().equals(classId))
                    .collect(Collectors.toList());
        }

        return logs;
    }

    @GetMapping("/excel")
    public ResponseEntity<byte[]> downloadExcel(
            @RequestParam(required = false) Long studentId,
            @RequestParam(required = false) Long batchId,
            @RequestParam(required = false) Long classId,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate) throws IOException {

        List<Attendance> logs = getFilteredLogs(studentId, batchId, classId, startDate, endDate);
        String title = "Attendance Report (" + 
                (startDate != null ? startDate : "Start") + " to " + (endDate != null ? endDate : "End") + ")";
        
        byte[] bytes = reportService.generateExcelReport(logs, title);

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"report.xlsx\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(bytes);
    }

    @GetMapping("/pdf")
    public ResponseEntity<byte[]> downloadPdf(
            @RequestParam(required = false) Long studentId,
            @RequestParam(required = false) Long batchId,
            @RequestParam(required = false) Long classId,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate) {

        List<Attendance> logs = getFilteredLogs(studentId, batchId, classId, startDate, endDate);
        String title = "Attendance Report (" + 
                (startDate != null ? startDate : "Start") + " to " + (endDate != null ? endDate : "End") + ")";
        
        byte[] bytes = reportService.generatePdfReport(logs, title);

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"report.pdf\"")
                .contentType(MediaType.APPLICATION_PDF)
                .body(bytes);
    }
}
