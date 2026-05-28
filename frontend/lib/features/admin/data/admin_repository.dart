import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AdminRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<Map<String, dynamic>>> getStudents({String? keyword}) async {
    final response = await _dio.get(
      '/admin/students',
      queryParameters: {
        if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> createStudent(Map<String, dynamic> payload) async {
    await _dio.post('/admin/students', data: payload);
  }

  Future<void> updateStudent(int id, Map<String, dynamic> payload) async {
    await _dio.put('/admin/students/$id', data: payload);
  }

  Future<void> deleteStudent(int id) async {
    await _dio.delete('/admin/students/$id');
  }

  Future<List<Map<String, dynamic>>> getCourses() async {
    final response = await _dio.get('/admin/courses');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> createCourse(Map<String, dynamic> payload) async {
    await _dio.post('/admin/courses', data: payload);
  }

  Future<void> updateCourse(int id, Map<String, dynamic> payload) async {
    await _dio.put('/admin/courses/$id', data: payload);
  }

  Future<void> deleteCourse(int id) async {
    await _dio.delete('/admin/courses/$id');
  }

  Future<Map<String, dynamic>> importCourses(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: File(filePath).uri.pathSegments.last),
    });
    final response = await _dio.post('/admin/courses/import', data: formData);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> saveManualGrade(Map<String, dynamic> payload) async {
    final response = await _dio.post('/admin/grades/manual', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> searchStudentSuggestions(String keyword) async {
    final response = await _dio.get(
      '/admin/grades/students/suggestions',
      queryParameters: {'keyword': keyword},
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getStudentTerms(String mssv) async {
    final response = await _dio.get('/admin/grades/students/$mssv/terms');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getStudentCoursesByTerm({
    required String mssv,
    required String academicYear,
    required String semester,
    String? keyword,
  }) async {
    final response = await _dio.get(
      '/admin/grades/students/$mssv/courses',
      queryParameters: {
        'academic_year': academicYear,
        'semester': semester,
        if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> importGrades({
    required String courseCode,
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'course_code': courseCode,
      'file': await MultipartFile.fromFile(filePath, filename: File(filePath).uri.pathSegments.last),
    });
    final response = await _dio.post('/admin/grades/import', data: formData);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
