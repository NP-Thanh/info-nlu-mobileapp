package com.example.nlu.entity;

public enum StudentStatus {
    /** Đang học */
    ACTIVE,
    /** Đã tốt nghiệp — vẫn đăng nhập và dùng app */
    GRADUATED,
    /** Vô hiệu hóa / tạm khóa — chặn API, không cho đăng nhập */
    LOCKED;

    public boolean allowsLogin() {
        return this == ACTIVE || this == GRADUATED;
    }

    public boolean allowsApiAccess() {
        return this == ACTIVE || this == GRADUATED;
    }
}
