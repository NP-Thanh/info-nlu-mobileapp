package com.example.nlu.service;

import com.example.nlu.entity.User;
import com.example.nlu.entity.UserDevice;
import com.example.nlu.repo.UserDeviceRepository;
import com.example.nlu.repo.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class DeviceService {

    private final UserDeviceRepository userDeviceRepository;
    private final UserRepository userRepository;

    @Transactional
    public void registerDevice(String username, String deviceToken, String deviceType) {
        if (deviceToken == null || deviceToken.isBlank()) {
            throw new RuntimeException("Device token không hợp lệ");
        }
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        // Mỗi user chỉ giữ 1 token mới nhất
        userDeviceRepository.deleteByUser_IdAndDeviceTokenNot(user.getId(), deviceToken);

        Optional<UserDevice> existing = userDeviceRepository.findByDeviceToken(deviceToken);
        if (existing.isPresent()) {
            UserDevice device = existing.get();
            device.setUser(user);
            device.setDeviceType(deviceType);
            userDeviceRepository.save(device);
            return;
        }

        UserDevice device = new UserDevice();
        device.setUser(user);
        device.setDeviceToken(deviceToken);
        device.setDeviceType(deviceType != null ? deviceType : "android");
        device.setCreatedAt(LocalDateTime.now());
        userDeviceRepository.save(device);
    }

    @Transactional
    public void unregisterDevice(String username, String deviceToken) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));
        userDeviceRepository.deleteByUser_IdAndDeviceToken(user.getId(), deviceToken);
    }
}
