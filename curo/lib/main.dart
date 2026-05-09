import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/fcm_service.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'firebase_options.dart';

/// Top-level FCM background handler — must be a global function (not a closure
/// or a class method) so the Dart isolate can locate it after a cold start.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this function is called.
  // The OS displays the notification automatically when the message has a
  // notification payload, so nothing extra is needed here.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register the background message handler before runApp.
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // Route all Flutter errors to Crashlytics in release builds.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('locale') ?? 'en';

  runApp(
    ProviderScope(
      overrides: [
        languageProvider.overrideWith(
          () => LanguageNotifier(Locale(savedLocale)),
        ),
      ],
      child: const CuroApp(),
    ),
  );
}

class CuroApp extends ConsumerStatefulWidget {
  const CuroApp({super.key});

  @override
  ConsumerState<CuroApp> createState() => _CuroAppState();
}

class _CuroAppState extends ConsumerState<CuroApp> {
  @override
  void initState() {
    super.initState();
    FcmService.init(
      onNotification: (notification) {
        ref.read(notificationsProvider.notifier).add(notification);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    return MaterialApp.router(
      title: 'CURO',
      theme: AppTheme.light,
      routerConfig: appRouter,
      locale: locale,
      builder: (context, child) => Directionality(
        textDirection: locale.languageCode == 'ur'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: child!,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
