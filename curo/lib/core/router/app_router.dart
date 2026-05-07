import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/labs/screens/lab_map_screen.dart';
import '../../features/reports/screens/report_upload_screen.dart';
import '../../features/medicines/screens/medicine_finder_screen.dart';
import '../../features/medicines/screens/prescription_scanner_screen.dart';
import '../../features/medicines/screens/scanned_medicines_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const signup = '/signup';
  static const login = '/login';
  static const otp = '/otp';
  static const home = '/home';
  static const labs = '/labs';
  static const reports = '/reports';
  static const medicines = '/medicines';
  static const medicineScanner = '/medicines/scanner';
  static const medicineResults = '/medicines/results';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, _) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, _) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (_, _) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, _) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      builder: (_, state) => OtpScreen(phone: state.extra as String? ?? ''),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (_, _) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.labs,
      builder: (_, _) => const LabMapScreen(),
    ),
    GoRoute(
      path: AppRoutes.reports,
      builder: (_, _) => const ReportUploadScreen(),
    ),
    GoRoute(
      path: AppRoutes.medicines,
      builder: (_, _) => const MedicineFinderScreen(),
    ),
    GoRoute(
      path: AppRoutes.medicineScanner,
      builder: (_, _) => const PrescriptionScannerScreen(),
    ),
    GoRoute(
      path: AppRoutes.medicineResults,
      builder: (_, _) => const ScannedMedicinesScreen(),
    ),
  ],
);
