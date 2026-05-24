import 'dart:io';

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class DeviceRepository {
  final Dio _dio = ApiClient.instance;

  Future<void> registerDevice(String token) async {
    await _dio.post('/devices/register', data: {
      'deviceToken': token,
      'deviceType': Platform.isIOS ? 'ios' : 'android',
    });
  }

  Future<void> unregisterDevice(String token) async {
    await _dio.delete('/devices', data: {
      'deviceToken': token,
      'deviceType': Platform.isIOS ? 'ios' : 'android',
    });
  }
}
