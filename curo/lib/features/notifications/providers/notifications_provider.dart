import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_models.dart';

final notificationsProvider = NotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});

class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        type: NotifType.labResult,
        title: 'Report Ready',
        body: 'Your CBC report from Apollo Diagnostics is ready to view.',
        time: now.subtract(const Duration(minutes: 2)),
        isRead: false,
      ),
      AppNotification(
        id: 'n2',
        type: NotifType.booking,
        title: 'Booking Confirmed',
        body: 'Test booked at Metropolis Lab for tomorrow at 9:00 AM.',
        time: now.subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      AppNotification(
        id: 'n3',
        type: NotifType.aiTrend,
        title: 'AI Health Trend',
        body: 'Your cholesterol levels show a declining trend. Keep it up!',
        time: now.subtract(const Duration(hours: 3)),
        isRead: false,
      ),
      AppNotification(
        id: 'n4',
        type: NotifType.medicine,
        title: 'Medicine Reminder',
        body: 'Time to take Metformin 500mg with food.',
        time: now.subtract(const Duration(days: 1, hours: 4)),
        isRead: true,
      ),
      AppNotification(
        id: 'n5',
        type: NotifType.labResult,
        title: 'Report Available',
        body: 'Your Urine Analysis report is now in your Health Locker.',
        time: now.subtract(const Duration(days: 1, hours: 10)),
        isRead: true,
      ),
    ];
  }

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }
}
