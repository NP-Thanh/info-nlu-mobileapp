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
}
