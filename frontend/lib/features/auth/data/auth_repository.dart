import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> login(String studentId, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'studentId': studentId,
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;

    // Lưu token vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    await prefs.setString('studentCode', data['studentCode']);
    await prefs.setString('fullName', data['fullName']);
    await prefs.setString('role', data['role']);

    return data;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
