import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../model/notification_model.dart';

class NotificationRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<AppNotification>> getNotifications() async {
    final response = await _dio.get('/notifications');
    return (response.data as List<dynamic>)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppNotification>> getUnreadNotifications() async {
    final response = await _dio.get('/notifications/unread');
    return (response.data as List<dynamic>)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(int id) async {
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> markAsReadMany(List<int> ids) async {
    await _dio.patch('/notifications/read', data: {'ids': ids});
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('/notifications/read-all');
  }

  Future<void> deleteNotification(int id) async {
    await _dio.delete('/notifications/$id');
  }

  Future<void> deleteNotifications(List<int> ids) async {
    await _dio.delete('/notifications', data: {'ids': ids});
  }
}
