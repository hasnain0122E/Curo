import 'package:firebase_messaging/firebase_messaging.dart';

enum NotifType { labResult, booking, aiTrend, medicine }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  final String id;
  final NotifType type;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        time: time,
        isRead: isRead ?? this.isRead,
      );

  /// Converts an FCM [RemoteMessage] into an [AppNotification].
  ///
  /// Expected FCM data payload:
  /// ```json
  /// { "type": "labResult" | "booking" | "aiTrend" | "medicine" }
  /// ```
  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    final data  = message.data;
    final notif = message.notification;

    final typeStr = data['type'] as String? ?? '';
    final type = switch (typeStr) {
      'booking'   => NotifType.booking,
      'aiTrend'   => NotifType.aiTrend,
      'medicine'  => NotifType.medicine,
      _           => NotifType.labResult,
    };

    return AppNotification(
      id:    message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type:  type,
      title: notif?.title ?? data['title'] as String? ?? 'CURO',
      body:  notif?.body  ?? data['body']  as String? ?? '',
      time:  message.sentTime ?? DateTime.now(),
      isRead: false,
    );
  }
}
