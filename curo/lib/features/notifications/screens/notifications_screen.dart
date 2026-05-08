import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/curo_app_bar.dart';
import '../models/notification_models.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final hasUnread = notifications.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CuroAppBar(
        title: 'Notifications',
        actions: hasUnread
            ? [
                GestureDetector(
                  onTap: notifier.markAllRead,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.r8),
                    ),
                    child: Text(
                      'Mark all read',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: notifications.isEmpty
          ? _EmptyState()
          : _NotificationsList(notifications: notifications, ref: ref),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_off_outlined,
              size: 56, color: AppColors.border),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'No notifications yet',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Grouped List ──────────────────────────────────────────────────────────────

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({
    required this.notifications,
    required this.ref,
  });

  final List<AppNotification> notifications;
  final WidgetRef ref;

  List<dynamic> _buildFlatList() {
    final Map<String, List<AppNotification>> groups = {};
    final now = DateTime.now();

    for (final n in notifications) {
      final diff = now.difference(n.time).inDays;
      final String key;
      if (diff == 0) {
        key = 'Today';
      } else if (diff == 1) {
        key = 'Yesterday';
      } else {
        key = DateFormat('MMMM d').format(n.time);
      }
      groups.putIfAbsent(key, () => []).add(n);
    }

    final List<dynamic> items = [];
    for (final entry in groups.entries) {
      items.add(entry.key);
      items.addAll(entry.value);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildFlatList();

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.s16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item is String) return _DateHeader(text: item);
        return _NotifItem(
          notification: item as AppNotification,
          onTap: () => ref
              .read(notificationsProvider.notifier)
              .markRead((item).id),
        );
      },
    );
  }
}

// ── Date Header ───────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          top: AppSpacing.s8, bottom: AppSpacing.s8),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Notification Item ─────────────────────────────────────────────────────────

class _NotifItem extends StatelessWidget {
  const _NotifItem({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  static Color _typeColor(NotifType type) => switch (type) {
        NotifType.labResult => AppColors.primary,
        NotifType.booking => AppColors.success,
        NotifType.aiTrend => const Color(0xFF8B5CF6),
        NotifType.medicine => const Color(0xFFF59E0B),
      };

  static IconData _typeIcon(NotifType type) => switch (type) {
        NotifType.labResult => Icons.description_outlined,
        NotifType.booking => Icons.calendar_month_outlined,
        NotifType.aiTrend => Icons.auto_awesome_rounded,
        NotifType.medicine => Icons.medication_outlined,
      };

  static String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('d MMM').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(notification.type);
    final icon = _typeIcon(notification.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s8),
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface
              : const Color(0xFFEBF8FE),
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(
            color: notification.isRead
                ? AppColors.border
                : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notification.title,
                            style: AppTextStyles.labelLarge),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.body, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.time),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
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
}
