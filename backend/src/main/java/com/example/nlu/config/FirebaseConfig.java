package com.example.nlu.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import java.io.FileInputStream;
import java.nio.file.Files;
import java.nio.file.Path;

@Slf4j
@Configuration
public class FirebaseConfig {

    @Value("${firebase.enabled:false}")
    private boolean enabled;

    @Value("${firebase.service-account-path:}")
    private String serviceAccountPath;

    @PostConstruct
    public void initFirebase() {
        if (!enabled) {
            log.info("Firebase FCM is disabled (firebase.enabled=false)");
            return;
        }
        if (serviceAccountPath == null || serviceAccountPath.isBlank()) {
            log.warn("Firebase enabled but FIREBASE_SERVICE_ACCOUNT_PATH is empty");
            return;
        }
        try {
            Path path = Path.of(serviceAccountPath);
            if (!Files.exists(path)) {
                log.warn("Firebase service account file not found: {}", serviceAccountPath);
                return;
            }
            if (FirebaseApp.getApps().isEmpty()) {
                try (FileInputStream stream = new FileInputStream(path.toFile())) {
                    FirebaseOptions options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(stream))
                            .build();
                    FirebaseApp.initializeApp(options);
                    log.info("Firebase Admin SDK initialized");
                }
            }
        } catch (Exception e) {
            log.error("Failed to initialize Firebase: {}", e.getMessage());
        }
    }
}
