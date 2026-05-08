import 'package:flutter_riverpod/flutter_riverpod.dart';

// Language provider lives in lib/providers/ and is re-exported here for
// backwards compatibility with any screen that imports profile_provider.dart.
export '../../../providers/language_provider.dart';

class UserProfile {
  const UserProfile({
    required this.name,
    required this.initials,
    required this.mediPoints,
    required this.reportsCount,
    required this.testsBooked,
  });

  final String name;
  final String initials;
  final int mediPoints;
  final int reportsCount;
  final int testsBooked;
}

final userProfileProvider = Provider<UserProfile>(
  (_) => const UserProfile(
    name: 'Ali Khan',
    initials: 'AK',
    mediPoints: 240,
    reportsCount: 12,
    testsBooked: 5,
  ),
);

