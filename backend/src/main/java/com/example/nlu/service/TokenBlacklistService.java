package com.example.nlu.service;

import com.example.nlu.jwt.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Date;

@Service
@RequiredArgsConstructor
public class TokenBlacklistService {

    private static final String PREFIX = "blacklist:";
    private static final String REVOKE_PREFIX = "revoked_user:";

    private final StringRedisTemplate redisTemplate;
    private final JwtUtil jwtUtil;

    public void blacklist(String token) {
        Date expiry = jwtUtil.extractExpiration(token);
        if (expiry == null) return;

        long ttlMillis = expiry.getTime() - System.currentTimeMillis();
        if (ttlMillis <= 0) return; // token đã hết hạn

        redisTemplate.opsForValue().set(PREFIX + token, "1", Duration.ofMillis(ttlMillis));
    }

    public boolean isBlacklisted(String token) {
        return Boolean.TRUE.equals(redisTemplate.hasKey(PREFIX + token));
    }

    /**
     * Revoke tất cả token của một user theo username.
     * Lưu timestamp revoke vào Redis với TTL = thời gian hết hạn token.
     * JwtAuthFilter sẽ check xem token được cấp trước thời điểm này không.
     */
    public void revokeAllTokensForUser(String username, Duration tokenExpiration) {
        long revokedAt = System.currentTimeMillis();
        redisTemplate.opsForValue().set(
                REVOKE_PREFIX + username,
                String.valueOf(revokedAt),
                tokenExpiration
        );
    }

    /**
     * Kiểm tra token có bị revoke theo username không.
     * Token bị revoke nếu issuedAt < revokedAt timestamp.
     */
    public boolean isRevokedForUser(String token) {
        try {
            String username = jwtUtil.extractUsername(token);
            String revokedAtStr = redisTemplate.opsForValue().get(REVOKE_PREFIX + username);
            if (revokedAtStr == null) return false;
            long revokedAt = Long.parseLong(revokedAtStr);
            Date issuedAt = jwtUtil.extractIssuedAt(token);
            if (issuedAt == null) return false;
            return issuedAt.getTime() < revokedAt;
        } catch (Exception e) {
            return false;
        }
    }
}
