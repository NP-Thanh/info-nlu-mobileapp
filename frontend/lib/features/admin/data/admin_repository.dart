import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AdminRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<Map<String, dynamic>>> getStudents({
    String? keyword,
    String? className,
    String? faculty,
    int? startYear,
    String? status,
  }) async {
    final response = await _dio.get(
      '/admin/students',
      queryParameters: {
        if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        if (className != null && className.trim().isNotEmpty) 'className': className.trim(),
        if (faculty != null && faculty.trim().isNotEmpty) 'faculty': faculty.trim(),
        if (startYear != null) 'startYear': startYear,
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<String>> getFilterSuggestions({required String type, String? keyword}) async {
    final response = await _dio.get(
      '/admin/students/filter-suggestions',
      queryParameters: {
        'type': type,
        if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((e) => e.toString()).toList();
  }

  Future<Map<String, dynamic>> getStudentDetail(int id) async {
    final response = await _dio.get('/admin/students/$id');
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
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

  Future<void> deleteStudentsBulk(List<int> ids) async {
    await _dio.delete('/admin/students', data: {'ids': ids});
  }

  Future<List<String>> getProgramFaculties() async {
    final response = await _dio.get('/admin/programs/faculties');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((e) => e.toString()).toList();
  }

  Future<List<String>> getProgramMajors(String faculty) async {
    final response = await _dio.get('/admin/programs/majors', queryParameters: {'faculty': faculty});
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((e) => e.toString()).toList();
  }

  Future<List<String>> getProgramSpecializations(String faculty, String major) async {
    final response = await _dio.get(
      '/admin/programs/specializations',
      queryParameters: {'faculty': faculty, 'major': major},
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((e) => e.toString()).toList();
  }

  Future<Map<String, dynamic>> resolveProgram(String faculty, String major, String specialization) async {
    final response = await _dio.get(
      '/admin/programs/resolve',
      queryParameters: {'faculty': faculty, 'major': major, 'specialization': specialization},
    );
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> getStudentLatestSchedule(int studentId) async {
    final response = await _dio.get('/admin/students/$studentId/schedule/latest');
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<void> updateSchedule(int scheduleId, Map<String, dynamic> payload) async {
    await _dio.put('/admin/schedules/$scheduleId', data: payload);
  }

  Future<void> deleteSchedule(int scheduleId) async {
    await _dio.delete('/admin/schedules/$scheduleId');
  }

  Future<List<Map<String, dynamic>>> getStudentGradeSemesters(int studentId) async {
    final response = await _dio.get('/admin/students/$studentId/grades/semesters');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getStudentGrades({
    required int studentId,
    required String academicYear,
    required String semester,
  }) async {
    final response = await _dio.get(
      '/admin/students/$studentId/grades',
      queryParameters: {'academic_year': academicYear, 'semester': semester},
    );
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
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

  Future<Map<String, dynamic>> previewCourses(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: File(filePath).uri.pathSegments.last),
    });
    final response = await _dio.post('/admin/courses/preview', data: formData);
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
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

  Future<Map<String, dynamic>> previewGrades({
    required String courseCode,
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'course_code': courseCode,
      'file': await MultipartFile.fromFile(filePath, filename: File(filePath).uri.pathSegments.last),
    });
    final response = await _dio.post('/admin/grades/preview', data: formData);
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
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

  // ── Admin Schedules ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAdminSchedules({
    String? keyword,
    String? semester,
    String? academicYear,
  }) async {
    final response = await _dio.get('/admin/schedules', queryParameters: {
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      if (semester != null && semester.trim().isNotEmpty) 'semester': semester.trim(),
      if (academicYear != null && academicYear.trim().isNotEmpty) 'academicYear': academicYear.trim(),
    });
    final data = (response.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<String>> getScheduleAcademicYears() async {
    final response = await _dio.get('/admin/schedules/academic-years');
    final data = (response.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data.map((e) => e.toString()).toList();
  }

  Future<Map<String, dynamic>> getAdminScheduleDetail(int scheduleId) async {
    final response = await _dio.get('/admin/schedules/$scheduleId');
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> createAdminSchedule(Map<String, dynamic> payload) async {
    final response = await _dio.post('/admin/schedules', data: payload);
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> updateAdminSchedule(int id, Map<String, dynamic> payload) async {
    final response = await _dio.put('/admin/schedules/$id', data: payload);
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<void> softDeleteAdminSchedule(int id) async {
    await _dio.delete('/admin/schedules/$id');
  }

  Future<void> softDeleteAdminSchedulesBulk(List<int> ids) async {
    await _dio.delete('/admin/schedules', data: {'ids': ids});
  }

  Future<Map<String, dynamic>> updateScheduleStudents(int scheduleId, List<int> studentIds) async {
    final response = await _dio.put('/admin/schedules/$scheduleId/students',
        data: {'studentIds': studentIds});
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> previewScheduleExcel(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: File(filePath).uri.pathSegments.last),
    });
    final response = await _dio.post('/admin/schedules/preview', data: formData);
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> importScheduleExcel(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: File(filePath).uri.pathSegments.last),
    });
    final response = await _dio.post('/admin/schedules/import', data: formData);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> getAllStudentsForSchedule({String? keyword}) async {
    final response = await _dio.get('/admin/students', queryParameters: {
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
    });
    final data = (response.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Admin Sections ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAdminSections({
    String? keyword,
    String? semester,
    String? academicYear,
  }) async {
    final response = await _dio.get('/admin/sections', queryParameters: {
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      if (semester != null && semester.trim().isNotEmpty) 'semester': semester.trim(),
      if (academicYear != null && academicYear.trim().isNotEmpty) 'academicYear': academicYear.trim(),
    });
    final data = (response.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<String>> getSectionAcademicYears() async {
    final response = await _dio.get('/admin/sections/academic-years');
    final data = (response.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data.map((e) => e.toString()).toList();
  }

  Future<Map<String, dynamic>> getAdminSectionDetail(int sectionId) async {
    final response = await _dio.get('/admin/sections/$sectionId');
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> createAdminSection(Map<String, dynamic> payload) async {
    final response = await _dio.post('/admin/sections', data: payload);
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> updateAdminSection(int id, Map<String, dynamic> payload) async {
    final response = await _dio.put('/admin/sections/$id', data: payload);
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<void> deleteAdminSection(int id) async {
    await _dio.delete('/admin/sections/$id');
  }

  Future<void> deleteAdminSectionsBulk(List<int> ids) async {
    await _dio.delete('/admin/sections', data: {'ids': ids});
  }

  Future<Map<String, dynamic>> addScheduleToSection(int sectionId, Map<String, dynamic> payload) async {
    final response = await _dio.post('/admin/sections/$sectionId/schedules', data: payload);
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> updateScheduleInSection(int scheduleId, Map<String, dynamic> payload) async {
    final response = await _dio.put('/admin/sections/schedules/$scheduleId', data: payload);
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<void> deleteScheduleInSection(int scheduleId) async {
    await _dio.delete('/admin/sections/schedules/$scheduleId');
  }

  Future<Map<String, dynamic>> updateSectionStudents(int sectionId, List<int> studentIds) async {
    final response = await _dio.put('/admin/sections/$sectionId/students',
        data: {'studentIds': studentIds});
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> previewSectionStudentsExcel(int sectionId, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: File(filePath).uri.pathSegments.last),
    });
    final response = await _dio.post('/admin/sections/$sectionId/students/preview', data: formData);
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> importSectionStudentsExcel(int sectionId, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: File(filePath).uri.pathSegments.last),
    });
    final response = await _dio.post('/admin/sections/$sectionId/students/import', data: formData);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> previewSectionsExcel(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: File(filePath).uri.pathSegments.last),
    });
    final response = await _dio.post('/admin/sections/preview', data: formData);
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> importSectionsExcel(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: File(filePath).uri.pathSegments.last),
    });
    final response = await _dio.post('/admin/sections/import', data: formData);
    return Map<String, dynamic>.from(response.data as Map);
  }

  // ── Admin Users ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAdminUsers({String? keyword}) async {
    final response = await _dio.get(
      '/admin/users',
      queryParameters: {
        if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createAdminUser({required String username, required String email}) async {
    final response = await _dio.post('/admin/users', data: {'username': username, 'email': email});
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<void> deleteAdminUsers(List<int> ids) async {
    await _dio.delete('/admin/users', data: {'ids': ids});
  }

  // ── Admin Chatbot Logs ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getChatbotLogs({
    String? keyword,
    bool? flagged,
  }) async {
    final response = await _dio.get('/admin/chatbot/logs', queryParameters: {
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      if (flagged != null) 'flagged': flagged,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getChatbotLogDetail(int id) async {
    final response = await _dio.get('/admin/chatbot/logs/$id');
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<void> flagChatbotLogs(List<int> ids, {required bool flagged}) async {
    await _dio.put('/admin/chatbot/logs/flag', data: {'ids': ids, 'flagged': flagged});
  }

  Future<void> deleteChatbotLogs(List<int> ids) async {
    await _dio.delete('/admin/chatbot/logs', data: {'ids': ids});
  }
}
