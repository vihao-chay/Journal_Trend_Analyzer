import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/app_notification.dart';
import '../viewmodels/firebase_features_view_model.dart';
import '../widgets/app_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<FirebaseFeaturesViewModel>().markAllNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseFeatures = context.watch<FirebaseFeaturesViewModel>();
    final notifications = firebaseFeatures.notifications;

    return Scaffold(
      key: const Key('notifications_screen'),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GradientAppBar(
        showBack: true,
        title: 'Thông báo',
        actions: [
          IconButton(
            key: const ValueKey('notifications_clear_button'),
            onPressed: notifications.isEmpty
                ? null
                : firebaseFeatures.clearNotifications,
            tooltip: 'Xóa tất cả',
            icon: const Icon(Icons.delete_outline, color: Colors.white),
          ),
        ],
      ),
      body: ScreenScroll(
        onRefresh: firebaseFeatures.refreshNotifications,
        children: [
          ScreenHeader(
            title: 'Trung tâm thông báo',
            subtitle: notifications.isEmpty
                ? 'Thông báo từ Firebase Cloud Messaging sẽ xuất hiện tại đây.'
                : 'Bạn có ${notifications.length} thông báo đã nhận từ FCM.',
            badge: '${firebaseFeatures.unreadNotificationCount} mới',
          ),
          const SizedBox(height: AppSpacing.medium),
          if (notifications.isEmpty)
            const SectionCard(
              child: AppEmptyState(
                icon: Icons.notifications_none,
                title: 'Chưa có thông báo',
                message:
                    'Gửi test message từ Firebase Console bằng FCM token trong tab Hồ sơ.',
              ),
            )
          else
            SectionCard(
              key: const ValueKey('notifications_list'),
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < notifications.length;
                    index++
                  ) ...[
                    _NotificationTile(
                      notification: notifications[index],
                      onTap: () {
                        firebaseFeatures.markNotificationRead(
                          notifications[index].id,
                        );
                      },
                    ),
                    if (index < notifications.length - 1)
                      const Divider(height: 18),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accentColor = notification.isRead
        ? colors.onSurfaceVariant
        : colors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notification.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active,
                color: accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: notification.isRead
                          ? FontWeight.w700
                          : FontWeight.w900,
                    ),
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${notification.source.name} • ${_formatDate(notification.receivedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }
}
