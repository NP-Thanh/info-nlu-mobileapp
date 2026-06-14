import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../navigation/app_navigator.dart';
import '../../features/auth/view/login_screen.dart';
import '../navigation/provider_scope_reset.dart';

class ApiClient {
  // static const String baseUrl = 'http://10.0.2.2:8080/api'; //local
  static const String baseUrl = 'http://10.0.130.116:8080/api'; //ktx
  // static const String baseUrl = 'http://10.152.161.243:8080/api'; //nlu

  static bool _isShowingSessionDialog = false;
  static bool _isLoggingOut = false;

  /// Gọi trước khi thực hiện logout để tắt session-expired interceptor
  static void setLoggingOut(bool value) => _isLoggingOut = value;

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          // Bỏ qua lỗi từ auth endpoints (login/logout) hoặc khi đang logout
          final path = error.requestOptions.path;
          if (_isLoggingOut || path.contains('/auth/')) {
            return handler.next(error);
          }

          if (status == 401 || status == 403) {
            // Nếu prefs không còn token thì đang trong quá trình logout — bỏ qua
            final prefs = await SharedPreferences.getInstance();
            if (prefs.getString('token') == null || prefs.getString('token')!.isEmpty) {
              return handler.next(error);
            }

            final data = error.response?.data;
            final message = (data is Map)
                ? (data['message'] as String? ?? _defaultMessage(status!))
                : _defaultMessage(status!);

            await _handleSessionInvalid(message);
          }
          handler.next(error);
        },
      ),
    );

  static Future<void> _handleSessionInvalid(String message) async {
    if (_isShowingSessionDialog) return;
    _isShowingSessionDialog = true;

    // Xóa toàn bộ dữ liệu lưu trữ
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      _isShowingSessionDialog = false;
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Thông báo'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );

    _isShowingSessionDialog = false;

    // Reset toàn bộ Riverpod state và điều hướng về login
    resetProviderScope();
    rootNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  static String _defaultMessage(int status) {
    if (status == 401) return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    return 'Tài khoản đang bị vô hiệu hóa. Vui lòng liên hệ quản trị viên.';
  }

  static Dio get instance => _dio;
}
