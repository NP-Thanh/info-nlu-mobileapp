# Thiết lập Push Notification (Firebase Cloud Messaging)

Ứng dụng dùng **Firebase Cloud Messaging (FCM)** — chuẩn cho Flutter/Android/iOS, miễn phí với quota lớn.

## Luồng hoạt động

1. **Thông báo mới**: Backend lưu vào bảng `notifications` → gửi FCM **data-only** tới token thiết bị (`user_devices`).
2. **App hiển thị đúng 1 lần** qua `flutter_local_notifications` (foreground + background).
3. **Mỗi user chỉ 1 token** — đăng ký mới sẽ xóa token cũ (tránh push trùng).
4. **Lịch học 7h sáng**: Cron server (`Asia/Ho_Chi_Minh`) tạo thông báo + push cho từng sinh viên có tài khoản.
5. **App**: Sau đăng nhập đăng ký FCM token qua `POST /api/devices/register`.

## 1. Tạo project Firebase

1. Vào [Firebase Console](https://console.firebase.google.com/) → **Add project**.
2. **Project settings** → **Your apps** → thêm app **Android**:
   - Package name: `com.example.frontend` (khớp `applicationId` trong `android/app/build.gradle.kts`).
3. Tải file **`google-services.json`** → đặt vào:
   ```
   frontend/android/app/google-services.json
   ```

## 2. Backend — Service Account

1. Firebase Console → **Project settings** → **Service accounts**.
2. **Generate new private key** → lưu file JSON (ví dụ `firebase-service-account.json`).
3. Thêm vào file `.env` ở thư mục `backend/`:

```env
FIREBASE_ENABLED=true
FIREBASE_SERVICE_ACCOUNT_PATH=T:/duong-dan/to/firebase-service-account.json
SCHEDULE_NOTIFICATION_ENABLED=true
```

4. Khởi động lại backend.

> Nếu `FIREBASE_ENABLED=false`, app vẫn chạy bình thường nhưng **không có push** (chỉ thông báo trong app).

## 3. Kiểm tra nhanh

- Đăng nhập app trên điện thoại thật (emulator cũng được nếu có Google Play).
- Log backend: `Firebase Admin SDK initialized`.
- Tạo thông báo thử bằng code `notificationService.createAndPush(...)` hoặc đợi 7h sáng cron lịch học.

## 4. Gửi thông báo từ code backend

```java
notificationService.createAndPush(user, "Tiêu đề", "Nội dung", "general");
```

## 5. iOS (tùy chọn)

Cần thêm app iOS trên Firebase, tải `GoogleService-Info.plist`, cấu hình APNs trong Apple Developer. Chi tiết: [FlutterFire messaging](https://firebase.flutter.dev/docs/messaging/overview).

## Các lựa chọn khác (không dùng trong project này)

| Giải pháp | Ghi chú |
|-----------|---------|
| **FCM** ✅ | Miễn phí, tích hợp Flutter tốt, backend tự gửi |
| OneSignal / Pusher | Dịch vụ bên thứ 3, thêm phụ thuộc |
| Chỉ local notification 7h | Không chạy khi app tắt, không đồng bộ server |
| WebSocket | App phải mở, tốn pin |

## API thiết bị

- `POST /api/devices/register` — body: `{ "deviceToken": "...", "deviceType": "android" }`
- `DELETE /api/devices` — hủy đăng ký khi đăng xuất
