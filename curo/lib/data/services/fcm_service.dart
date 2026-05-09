import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:curo/features/notifications/models/notification_models.dart';

class FcmService {
  FcmService._();

  static final _messaging = FirebaseMessaging.instance;

  /// Initialise FCM. Call once from [CuroApp] initState.
  ///
  /// [onNotification] is invoked every time a new [AppNotification] arrives —
  /// whether the app is in the foreground, background-tapped, or cold-started
  /// from a notification tap.
  static Future<void> init({
    required void Function(AppNotification) onNotification,
  }) async {
    // 1. Request permission (required on iOS; Android 13+ with POST_NOTIFICATIONS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Foreground messages — OS does NOT auto-display these on Android, so
    //    we add them to the in-app list immediately.
    FirebaseMessaging.onMessage.listen((message) {
      onNotification(AppNotification.fromRemoteMessage(message));
    });

    // 3. User tapped a notification while the app was in the background.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNotification(AppNotification.fromRemoteMessage(message));
    });

    // 4. User tapped a notification that launched the app from terminated state.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      onNotification(AppNotification.fromRemoteMessage(initial));
    }

    // 5. Log the registration token so it can be used for targeted pushes.
    final token = await _messaging.getToken();
    // ignore: avoid_print
    if (token != null) print('[FCM] Device token: $token');

    // Refresh token listener (token can rotate)
    _messaging.onTokenRefresh.listen((newToken) {
      // ignore: avoid_print
      print('[FCM] Token refreshed: $newToken');
      // TODO: persist newToken to Firestore users/{uid}/fcmToken when needed
    });
  }
}
