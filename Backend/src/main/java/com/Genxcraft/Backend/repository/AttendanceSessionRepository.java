package com.Genxcraft.Backend.repository;

import com.Genxcraft.Backend.entity.AttendanceSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface AttendanceSessionRepository extends JpaRepository<AttendanceSession, Long> {
    Optional<AttendanceSession> findByBatchIdAndDate(Long batchId, LocalDate date);
    Optional<AttendanceSession> findByBatchIdAndDateAndSubjectId(Long batchId, LocalDate date, Long subjectId);
    List<AttendanceSession> findByDate(LocalDate date);
    List<AttendanceSession> findByTeacherId(Long teacherId);
}
