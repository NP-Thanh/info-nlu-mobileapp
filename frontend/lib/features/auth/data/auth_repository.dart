import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> login(String studentId, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'studentId': studentId,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }
}
