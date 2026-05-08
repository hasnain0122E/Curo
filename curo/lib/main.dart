import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/providers/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class CuroApp extends ConsumerWidget {
  const CuroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
