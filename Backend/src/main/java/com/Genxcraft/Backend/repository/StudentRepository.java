package com.Genxcraft.Backend.repository;

import com.Genxcraft.Backend.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StudentRepository extends JpaRepository<Student, Long> {
    Optional<Student> findByStudentId(String studentId);
    Optional<Student> findByQrCodeToken(String qrCodeToken);
    List<Student> findByBatchId(Long batchId);
    long countByBatchId(Long batchId);
    boolean existsByStudentId(String studentId);
}
