package com.Genxcraft.Backend.repository;

import com.Genxcraft.Backend.entity.Subject;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SubjectRepository extends JpaRepository<Subject, Long> {
    List<Subject> findByClazzId(Long clazzId);
}
