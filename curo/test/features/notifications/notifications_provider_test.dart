import 'package:curo/features/notifications/models/notification_models.dart';
import 'package:curo/features/notifications/providers/notifications_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _makeNotif(String id, {bool isRead = false}) => AppNotification(
      id: id,
      type: NotifType.labResult,
      title: 'Result Ready',
      body: 'Your CBC result is ready.',
      time: DateTime(2024, 6, 1),
      isRead: isRead,
    );

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  // ── initial state ──────────────────────────────────────────────────────────

  test('initial notification list is empty', () {
    expect(container.read(notificationsProvider), isEmpty);
  });

  test('initial unread count is 0', () {
    expect(container.read(unreadCountProvider), 0);
  });

  // ── add ────────────────────────────────────────────────────────────────────

  group('NotificationsNotifier.add', () {
    test('adds a notification to the list', () {
      container.read(notificationsProvider.notifier).add(_makeNotif('n1'));
      expect(container.read(notificationsProvider), hasLength(1));
    });

    test('prepends so newest appears first (LIFO)', () {
      final notifier = container.read(notificationsProvider.notifier);
      notifier.add(_makeNotif('n1'));
      notifier.add(_makeNotif('n2'));
      notifier.add(_makeNotif('n3'));

      final ids = container.read(notificationsProvider).map((n) => n.id).toList();
      expect(ids, ['n3', 'n2', 'n1']);
    });

    test('new notification has isRead = false', () {
      container.read(notificationsProvider.notifier).add(_makeNotif('n1'));
      expect(container.read(notificationsProvider).first.isRead, isFalse);
    });

    test('increments unread count', () {
      final notifier = container.read(notificationsProvider.notifier);
      notifier.add(_makeNotif('n1'));
      notifier.add(_makeNotif('n2'));
      expect(container.read(unreadCountProvider), 2);
    });
  });

  // ── markRead ───────────────────────────────────────────────────────────────

  group('NotificationsNotifier.markRead', () {
    test('marks the correct notification as read', () {
      final notifier = container.read(notificationsProvider.notifier);
      notifier.add(_makeNotif('n1'));
      notifier.add(_makeNotif('n2'));

      notifier.markRead('n1');

      final state = container.read(notificationsProvider);
      final n1 = state.firstWhere((n) => n.id == 'n1');
      final n2 = state.firstWhere((n) => n.id == 'n2');
      expect(n1.isRead, isTrue);
      expect(n2.isRead, isFalse);
    });

    test('does not alter other fields when marking read', () {
      final notifier = container.read(notificationsProvider.notifier);
      notifier.add(_makeNotif('n1'));
      notifier.markRead('n1');

      final n1 = container.read(notificationsProvider).first;
      expect(n1.title, 'Result Ready');
      expect(n1.type, NotifType.labResult);
    });

    test('decrements unread count after markRead', () {
      final notifier = container.read(notificationsProvider.notifier);
      notifier.add(_makeNotif('n1'));
      notifier.add(_makeNotif('n2'));
      expect(container.read(unreadCountProvider), 2);

      notifier.markRead('n1');
      expect(container.read(unreadCountProvider), 1);
    });

    test('no-ops when id does not exist', () {
      final notifier = container.read(notificationsProvider.notifier);
      notifier.add(_makeNotif('n1'));
      notifier.markRead('nonexistent');

      expect(container.read(notificationsProvider).first.isRead, isFalse);
    });
  });

  // ── markAllRead ────────────────────────────────────────────────────────────

  group('NotificationsNotifier.markAllRead', () {
    test('marks every notification as read', () {
      final notifier = container.read(notificationsProvider.notifier);
      notifier.add(_makeNotif('n1'));
      notifier.add(_makeNotif('n2'));
      notifier.add(_makeNotif('n3'));

      notifier.markAllRead();

      final all = container.read(notificationsProvider);
      expect(all.every((n) => n.isRead), isTrue);
    });

    test('reduces unread count to 0', () {
      final notifier = container.read(notificationsProvider.notifier);
      notifier.add(_makeNotif('n1'));
      notifier.add(_makeNotif('n2'));

      notifier.markAllRead();
      expect(container.read(unreadCountProvider), 0);
    });

    test('no-ops on an already-empty list', () {
      container.read(notificationsProvider.notifier).markAllRead();
      expect(container.read(notificationsProvider), isEmpty);
    });
  });

  // ── unreadCountProvider ────────────────────────────────────────────────────

  group('unreadCountProvider', () {
    test('counts only unread notifications', () {
      final notifier = container.read(notificationsProvider.notifier);
      notifier.add(_makeNotif('n1'));
      notifier.add(_makeNotif('n2'));
      notifier.add(_makeNotif('n3'));
      notifier.markRead('n2');

      expect(container.read(unreadCountProvider), 2);
    });

    test('returns 0 when all are read', () {
      final notifier = container.read(notificationsProvider.notifier);
      notifier.add(_makeNotif('n1'));
      notifier.markRead('n1');

      expect(container.read(unreadCountProvider), 0);
    });
  });

  // ── AppNotification.copyWith ───────────────────────────────────────────────

  group('AppNotification.copyWith', () {
    test('toggles isRead while preserving other fields', () {
      final n = _makeNotif('n1');
      final marked = n.copyWith(isRead: true);

      expect(marked.isRead, isTrue);
      expect(marked.id, 'n1');
      expect(marked.title, n.title);
      expect(marked.type, n.type);
      expect(marked.time, n.time);
    });
  });
}
