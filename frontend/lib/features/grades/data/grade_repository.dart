import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../model/grade_model.dart';

class GradeRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<SemesterOption>> getAllSemesters() async {
    final response = await _dio.get('/student/grades/semesters');
    return (response.data as List<dynamic>)
        .map((e) => SemesterOption(
              semester: e['semester'] as String,
              academicYear: e['academicYear'] as String,
            ))
        .toList();
  }

  Future<GradeData> getGrades(String academicYear, String semester) async {
    final response = await _dio.get('/student/grades', queryParameters: {
      'academicYear': academicYear,
      'semester': semester,
    });
    return GradeData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SemesterSummary> getSemesterSummary(
      String academicYear, String semester) async {
    final response =
        await _dio.get('/student/semester-summary', queryParameters: {
      'academicYear': academicYear,
      'semester': semester,
    });
    return SemesterSummary.fromJson(response.data as Map<String, dynamic>);
  }
}
