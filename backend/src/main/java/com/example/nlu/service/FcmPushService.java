package com.example.nlu.service;

import com.example.nlu.entity.UserDevice;
import com.example.nlu.repo.UserDeviceRepository;
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Slf4j
@Service
@RequiredArgsConstructor
public class FcmPushService {

    private final UserDeviceRepository userDeviceRepository;

    @Value("${firebase.enabled:false}")
    private boolean enabled;

    public boolean isAvailable() {
        return enabled && !FirebaseApp.getApps().isEmpty();
    }

    public void sendToUser(Long userId, String title, String body, Map<String, String> data) {
        if (!isAvailable()) {
            log.debug("FCM skipped (not configured) for user {}", userId);
            return;
        }
        List<UserDevice> devices = userDeviceRepository.findByUser_Id(userId);
        devices.stream()
                .map(UserDevice::getDeviceToken)
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(t -> !t.isEmpty())
                .distinct()
                .forEach(token -> sendToToken(token, title, body, data));
    }

    /**
     * Chỉ gửi data payload
     */
    public void sendToToken(String token, String title, String body, Map<String, String> data) {
        if (!isAvailable() || token == null || token.isBlank()) {
            return;
        }
        try {
            String shortBody = body.length() > 500 ? body.substring(0, 497) + "..." : body;

            Map<String, String> payload = new HashMap<>();
            if (data != null) {
                payload.putAll(data);
            }
            payload.put("title", title);
            payload.put("body", shortBody);

            Message message = Message.builder()
                    .setToken(token)
                    .putAllData(payload)
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .build())
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            log.debug("FCM sent: {}", response);
        } catch (FirebaseMessagingException e) {
            log.warn("FCM failed for token {}: {}", token.substring(0, Math.min(12, token.length())), e.getMessage());
            if (isInvalidToken(e)) {
                userDeviceRepository.findByDeviceToken(token).ifPresent(userDeviceRepository::delete);
            }
        }
    }

    private boolean isInvalidToken(FirebaseMessagingException e) {
        String msg = e.getMessage() != null ? e.getMessage().toLowerCase() : "";
        return msg.contains("unregistered") || msg.contains("not-found")
                || msg.contains("invalid-registration");
    }
}
