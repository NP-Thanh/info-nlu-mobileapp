package com.example.nlu.jwt;

import com.example.nlu.entity.Student;
import com.example.nlu.entity.StudentStatus;
import com.example.nlu.repo.StudentRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class StudentAccessFilter extends OncePerRequestFilter {

    private final StudentRepository studentRepository;
    private final ObjectMapper objectMapper;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String path = request.getRequestURI();

        if (path.startsWith("/api/auth") || path.startsWith("/api/admin")) {
            filterChain.doFilter(request, response);
            return;
        }

        var auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            filterChain.doFilter(request, response);
            return;
        }

        boolean isStudent = auth.getAuthorities().stream()
                .anyMatch(a -> "ROLE_STUDENT".equals(a.getAuthority()));
        if (!isStudent) {
            filterChain.doFilter(request, response);
            return;
        }

        Student student = studentRepository.findByStudentCode(auth.getName()).orElse(null);
        if (student != null && !student.getStatus().allowsApiAccess()) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            objectMapper.writeValue(response.getWriter(),
                    Map.of("message", disabledMessage(student.getStatus())));
            return;
        }

        filterChain.doFilter(request, response);
    }

    private String disabledMessage(StudentStatus status) {
        return "Tài khoản đang bị vô hiệu hóa";
    }
}
