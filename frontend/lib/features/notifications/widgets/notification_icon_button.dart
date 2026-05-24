import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../notification_navigation.dart';
import '../providers/notification_provider.dart';

/// Nút chuông thông báo dùng chung — hiện chấm đỏ khi có thông báo chưa đọc.
class NotificationIconButton extends ConsumerWidget {
  final Color? iconColor;

  const NotificationIconButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = ref.watch(notificationBadgeProvider) > 0;
    final color = iconColor ?? AppColors.textPrimary;

    return IconButton(
      tooltip: 'Thông báo',
      onPressed: () => openNotificationScreen(context, ref),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: color, size: 26),
          if (hasUnread)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE53935).withValues(alpha: 0.45),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
