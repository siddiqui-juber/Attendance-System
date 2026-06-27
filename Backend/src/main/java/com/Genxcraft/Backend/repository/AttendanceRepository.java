package com.Genxcraft.Backend.repository;

import com.Genxcraft.Backend.entity.Attendance;
import com.Genxcraft.Backend.entity.AttendanceStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface AttendanceRepository extends JpaRepository<Attendance, Long> {
    Optional<Attendance> findByStudentIdAndDateAndBatchId(Long studentId, LocalDate date, Long batchId);
    List<Attendance> findByDateAndBatchId(LocalDate date, Long batchId);
    List<Attendance> findByStudentId(Long studentId);
    List<Attendance> findByBatchIdAndDate(Long batchId, LocalDate date);
    List<Attendance> findByDate(LocalDate date);
    long countByDateAndStatus(LocalDate date, AttendanceStatus status);

    List<Attendance> findByDateBetween(LocalDate startDate, LocalDate endDate);
    List<Attendance> findByStudentIdAndDateBetween(Long studentId, LocalDate startDate, LocalDate endDate);
    List<Attendance> findByBatchIdAndDateBetween(Long batchId, LocalDate startDate, LocalDate endDate);
}
