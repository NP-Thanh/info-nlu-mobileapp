package com.example.nlu.repo;

import com.example.nlu.entity.UserDevice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserDeviceRepository extends JpaRepository<UserDevice, Long> {

    List<UserDevice> findByUser_Id(Long userId);

    Optional<UserDevice> findByDeviceToken(String deviceToken);

    void deleteByUser_IdAndDeviceToken(Long userId, String deviceToken);

    void deleteByUser_IdAndDeviceTokenNot(Long userId, String deviceToken);

    void deleteByUser_Id(Long userId);
}
