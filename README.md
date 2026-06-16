# Info NLU

Ứng dụng di động hỗ trợ sinh viên trường Đại học Nông Lâm TP.HCM (NLU) tra cứu thông tin học tập.

---

## Tính năng chính

- **Thông tin cá nhân** — Xem thông tin sinh viên, chương trình học
- **Thời khóa biểu** — Tra cứu TKB theo học kỳ, xem lịch học mới nhất
- **Điểm số** — Xem điểm từng môn, tổng kết học kỳ theo từng năm học
- **Thông báo** — Nhận thông báo từ nhà trường, đánh dấu đã đọc, xóa thông báo
- **Chatbot** — Hỏi đáp thông tin học tập bằng ngôn ngữ tự nhiên, xem lịch sử hội thoại
- **Quản trị (Admin)** — Quản lý sinh viên, lịch học, lớp học phần, gửi thông báo

---

## Công nghệ sử dụng

| Thành phần | Công nghệ |
|------------|-----------|
| Mobile | Flutter |
| Backend | Spring Boot (Java) |
| Xác thực | JWT + Firebase |
| Push Notification | Firebase Cloud Messaging |

---

## Cài đặt ứng dụng (Android)

1. Tải file APK: [**Nhấn vào đây để tải**](https://github.com/NP-Thanh/info-nlu-mobileapp/releases/download/v1.0.0/app-release.apk)
2. Trên điện thoại Android, vào **Cài đặt → Bảo mật → Cho phép cài từ nguồn không rõ**
3. Mở file APK vừa tải và nhấn **Cài đặt**

> Yêu cầu Android 6.0 trở lên

---

## Chạy dự án (Development)

### Backend

```bash
cd backend
./mvnw spring-boot:run
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```
