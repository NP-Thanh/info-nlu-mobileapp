package com.example.nlu.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

@Slf4j
@Configuration
public class FirebaseConfig {

    @Value("${firebase.enabled:false}")
    private boolean enabled;

    // Ưu tiên dùng JSON content (cho Railway/cloud), fallback về file path (cho local dev)
    @Value("${firebase.service-account-json:}")
    private String serviceAccountJson;

    @Value("${firebase.service-account-path:}")
    private String serviceAccountPath;

    @PostConstruct
    public void initFirebase() {
        if (!enabled) {
            log.info("Firebase FCM is disabled (firebase.enabled=false)");
            return;
        }
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                GoogleCredentials credentials = loadCredentials();
                if (credentials == null) return;
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(credentials)
                        .build();
                FirebaseApp.initializeApp(options);
                log.info("Firebase Admin SDK initialized");
            }
        } catch (Exception e) {
            log.error("Failed to initialize Firebase: {}", e.getMessage());
        }
    }

    private GoogleCredentials loadCredentials() throws Exception {
        // Ưu tiên JSON content từ env var (Railway/cloud deployment)
        if (serviceAccountJson != null && !serviceAccountJson.isBlank()) {
            byte[] jsonBytes = serviceAccountJson.getBytes(StandardCharsets.UTF_8);
            return GoogleCredentials.fromStream(new ByteArrayInputStream(jsonBytes));
        }
        // Fallback: đọc từ file path (local dev)
        if (serviceAccountPath != null && !serviceAccountPath.isBlank()) {
            Path path = Path.of(serviceAccountPath);
            if (!Files.exists(path)) {
                log.warn("Firebase service account file not found: {}", serviceAccountPath);
                return null;
            }
            try (FileInputStream stream = new FileInputStream(path.toFile())) {
                return GoogleCredentials.fromStream(stream);
            }
        }
        log.warn("Firebase enabled but no credentials provided (set FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_PATH)");
        return null;
    }
}
