import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../model/schedule_model.dart';

class ScheduleRepository {
  final Dio _dio = ApiClient.instance;

  Future<ScheduleData> getLatestSchedule() async {
    final response = await _dio.get('/schedule/latest');
    return ScheduleData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ScheduleData> getSchedule(String academicYear, String semester) async {
    final response = await _dio.get('/schedule', queryParameters: {
      'academicYear': academicYear,
      'semester': semester,
    });
    return ScheduleData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ScheduleData>> getAllSemesters() async {
    final response = await _dio.get('/schedule/all');
    return (response.data as List<dynamic>)
        .map((e) => ScheduleData.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
