package com.Genxcraft.Backend.repository;

import com.Genxcraft.Backend.entity.Clazz;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ClazzRepository extends JpaRepository<Clazz, Long> {
    Optional<Clazz> findByName(String name);
}
