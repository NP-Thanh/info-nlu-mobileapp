import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/app_navigator.dart';
import '../../features/notifications/data/device_repository.dart';
import '../../features/notifications/view/notification_screen.dart';

const _channelId = 'nlu_notifications';
const _channelName = 'Thông báo NLU';

final FlutterLocalNotificationsPlugin _backgroundLocalNotifications =
    FlutterLocalNotificationsPlugin();
bool _backgroundLocalReady = false;

Future<void> _ensureBackgroundNotificationsReady() async {
  if (_backgroundLocalReady || !Platform.isAndroid) return;
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _backgroundLocalNotifications.initialize(
    const InitializationSettings(android: androidInit),
  );
  await _backgroundLocalNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Thông báo từ hệ thống NLU',
          importance: Importance.high,
        ),
      );
  _backgroundLocalReady = true;
}

int _notificationId(RemoteMessage message) {
  final id = message.data['notificationId'];
  if (id != null) {
    final parsed = int.tryParse(id);
    if (parsed != null) return parsed;
  }
  return message.hashCode;
}

String? _title(RemoteMessage message) =>
    message.data['title'] ?? message.notification?.title;

String? _body(RemoteMessage message) =>
    message.data['body'] ?? message.notification?.body;

Future<void> _displayPushNotification(
  RemoteMessage message,
  FlutterLocalNotificationsPlugin plugin,
) async {
  final title = _title(message);
  final body = _body(message);
  if (title == null || title.isEmpty) return;

  await plugin.show(
    _notificationId(message),
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Thông báo từ hệ thống NLU',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
    payload: 'notifications',
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _ensureBackgroundNotificationsReady();
  await _displayPushNotification(message, _backgroundLocalNotifications);
}

/// Khởi tạo FCM — mỗi push chỉ hiển thị đúng 1 lần qua local notifications.
class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final DeviceRepository _deviceRepo = DeviceRepository();

  static bool _initialized = false;
  static String? _currentToken;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      if (Platform.isAndroid) {
        const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
        const initSettings = InitializationSettings(android: androidInit);
        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onLocalNotificationTap,
        );
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                _channelId,
                _channelName,
                description: 'Thông báo từ hệ thống NLU',
                importance: Importance.high,
              ),
            );
      }

      await _requestPermission();

      // Data-only từ server → hiển thị 1 lần (không còn trùng với notification payload hệ thống)
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _scheduleOpenNotifications();
      }

      _messaging.onTokenRefresh.listen((token) async {
        _currentToken = token;
        await _registerTokenIfLoggedIn(token);
      });

      _initialized = true;
      debugPrint('PushNotificationService initialized');
    } catch (e, st) {
      debugPrint('PushNotificationService init skipped: $e\n$st');
    }
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');
  }

  static Future<void> registerTokenWithBackend() async {
    if (!_initialized) return;
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      _currentToken = token;
      await _registerTokenIfLoggedIn(token);
    } catch (e) {
      debugPrint('FCM register token failed: $e');
    }
  }

  static Future<void> unregisterOnLogout() async {
    if (!_initialized || _currentToken == null) return;
    try {
      await _deviceRepo.unregisterDevice(_currentToken!);
    } catch (e) {
      debugPrint('FCM unregister failed: $e');
    }
  }

  static Future<void> _registerTokenIfLoggedIn(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('token');
    if (jwt == null || jwt.isEmpty) return;
    await _deviceRepo.registerDevice(token);
    debugPrint('FCM token registered with backend');
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    await _displayPushNotification(message, _localNotifications);
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    _scheduleOpenNotifications();
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == 'notifications') {
      _scheduleOpenNotifications();
    }
  }

  static void _scheduleOpenNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = rootNavigatorKey.currentState;
      if (navigator == null) return;
      navigator.push(
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      );
    });
  }
}
