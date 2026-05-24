import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/notification_provider.dart';
import 'view/notification_screen.dart';

Future<void> openNotificationScreen(BuildContext context, WidgetRef ref) async {
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const NotificationScreen()),
  );
  await ref.read(notificationBadgeProvider.notifier).refresh();
}
