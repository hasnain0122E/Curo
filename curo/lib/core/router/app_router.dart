import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/labs/models/lab_booking_models.dart';
import '../../features/labs/providers/lab_map_provider.dart';
import '../../features/labs/screens/lab_map_screen.dart';
import '../../features/labs/screens/lab_detail_screen.dart';
import '../../features/labs/screens/lab_booking_screen.dart';
import '../../features/labs/screens/my_bookings_screen.dart';
import '../../data/models/report_model.dart';
import '../../features/reports/screens/health_locker_screen.dart';
import '../../features/reports/screens/report_detail_screen.dart';
import '../../features/reports/screens/report_upload_screen.dart';
import '../../features/medicines/screens/medicine_finder_screen.dart';
import '../../features/medicines/screens/prescription_scanner_screen.dart';
import '../../features/medicines/screens/scanned_medicines_screen.dart';
import '../../features/labs/screens/lab_test_scanner_screen.dart';
import '../../features/labs/screens/lab_test_scan_result_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/medipoints/screens/medipoints_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const signup = '/signup';
  static const login = '/login';
  static const otp = '/otp';
  static const home = '/home';
  static const labs = '/labs';
  static const labDetail = '/labs/detail';
  static const labBooking = '/labs/booking';
  static const myBookings = '/labs/bookings';
  static const reports = '/reports';
  static const reportUpload = '/reports/upload';
  static const reportDetail = '/reports/detail';
  static const medicines = '/medicines';
  static const medicineScanner = '/medicines/scanner';
  static const medicineResults = '/medicines/results';
  static const labTestScanner = '/labs/test-scanner';
  static const labTestScanResult = '/labs/test-result';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const medipoints = '/medipoints';
}

// Routes accessible without authentication
const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.signup,
  AppRoutes.login,
  AppRoutes.otp,
};

// Notifier that refreshes GoRouter whenever Firebase auth state changes
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }
  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authNotifier = _AuthChangeNotifier();

String? _authRedirect(BuildContext context, GoRouterState state) {
  final isLoggedIn = FirebaseAuth.instance.currentUser != null;
  final loc = state.matchedLocation;
  final isPublic = _publicRoutes.contains(loc);

  if (!isLoggedIn && !isPublic) return AppRoutes.login;
  return null;
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: _authNotifier,
  redirect: _authRedirect,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, _) => const OnboardingScreen(),
    ),
    GoRoute(path: AppRoutes.signup, builder: (_, _) => const SignupScreen()),
    GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
    GoRoute(
      path: AppRoutes.otp,
      builder: (_, state) => OtpScreen(phone: state.extra as String? ?? ''),
    ),
    GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
    GoRoute(path: AppRoutes.labs, builder: (_, _) => const LabMapScreen()),
    GoRoute(
      path: AppRoutes.labDetail,
      builder: (_, state) => LabDetailScreen(lab: state.extra as LabLocation),
    ),
    GoRoute(
      path: AppRoutes.labBooking,
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return LabBookingScreen(
          lab: extra['lab'] as LabLocation,
          test: extra['test'] as LabTest,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.myBookings,
      builder: (_, _) => const MyBookingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.reports,
      builder: (_, _) => const HealthLockerScreen(),
    ),
    GoRoute(
      path: AppRoutes.reportUpload,
      builder: (_, _) => const ReportUploadScreen(),
    ),
    GoRoute(
      path: AppRoutes.reportDetail,
      builder: (_, state) =>
          ReportDetailScreen(report: state.extra as ReportModel),
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
    GoRoute(
      path: AppRoutes.labTestScanner,
      builder: (_, _) => const LabTestScannerScreen(),
    ),
    GoRoute(
      path: AppRoutes.labTestScanResult,
      builder: (_, _) => const LabTestScanResultScreen(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (_, _) => const NotificationsScreen(),
    ),
    GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileScreen()),
    GoRoute(
      path: AppRoutes.medipoints,
      builder: (_, _) => const MedipointsScreen(),
    ),
  ],
);
