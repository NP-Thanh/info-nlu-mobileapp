package com.example.nlu.repo;

import com.example.nlu.entity.PasswordReset;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PasswordResetRepository extends JpaRepository<PasswordReset, Long> {
}
