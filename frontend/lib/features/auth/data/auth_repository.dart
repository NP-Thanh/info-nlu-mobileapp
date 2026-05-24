import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/push_notification_service.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> login(String studentId, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'studentId': studentId,
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token'] ?? '');
    await prefs.setString('studentCode', data['studentCode'] ?? '');
    await prefs.setString('fullName', data['fullName'] ?? '');
    await prefs.setString('role', data['role'] ?? '');

    return data;
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post('/auth/change-password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });
      if (response.statusCode != 200) {
        throw Exception(response.data?['message'] ?? 'Đổi mật khẩu thất bại');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Đổi mật khẩu thất bại';
      throw Exception(msg);
    }
  }

  Future<void> logout() async {
    try {
      await PushNotificationService.unregisterOnLogout();
      await _dio.post('/auth/logout');
    } catch (_) {
      // Bỏ qua lỗi network
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }
}
