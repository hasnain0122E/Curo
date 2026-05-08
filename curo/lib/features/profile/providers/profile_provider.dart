import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/medipoints_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/report_provider.dart';

export '../../../providers/language_provider.dart';

// ── UserProfile model ─────────────────────────────────────────────────────────

class UserProfile {
  const UserProfile({
    required this.name,
    required this.initials,
    required this.email,
    required this.mediPoints,
    required this.reportsCount,
    required this.testsBooked,
  });

  final String name;
  final String initials;
  final String email;
  final int mediPoints;
  final int reportsCount;
  final int testsBooked;
}

// ── Provider — derives from Firebase streams ──────────────────────────────────

final userProfileProvider = Provider<UserProfile>((ref) {
  final userModel = ref.watch(currentUserProvider).asData?.value;
  final mediPoints = ref.watch(medipointsProvider);
  final reports = ref.watch(userReportsProvider).asData?.value ?? [];
  final bookings = ref.watch(userBookingsProvider).asData?.value ?? [];

  final name = userModel?.name ?? '';
  final firstName = userModel?.firstName ?? '';
  final lastName = userModel?.lastName ?? '';
  final email = userModel?.email ?? '';

  final displayName = name.isNotEmpty ? name : 'User';
  final initials = _buildInitials(firstName, lastName, displayName);

  return UserProfile(
    name: displayName,
    initials: initials,
    email: email,
    mediPoints: mediPoints,
    reportsCount: reports.length,
    testsBooked: bookings.length,
  );
});

String _buildInitials(String first, String last, String fallbackName) {
  if (first.isNotEmpty && last.isNotEmpty) {
    return '${first[0]}${last[0]}'.toUpperCase();
  }
  if (first.isNotEmpty) return first[0].toUpperCase();
  final parts = fallbackName.trim().split(' ').where((s) => s.isNotEmpty).toList();
  if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  if (parts.isNotEmpty) return parts.first[0].toUpperCase();
  return 'U';
}
