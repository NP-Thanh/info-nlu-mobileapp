import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../model/student_info.dart';

class StudentRepository {
  final Dio _dio = ApiClient.instance;

  Future<StudentInfo> getStudentInfo() async {
    final response = await _dio.get('/student/info');
    return StudentInfo.fromJson(response.data as Map<String, dynamic>);
  }
}
