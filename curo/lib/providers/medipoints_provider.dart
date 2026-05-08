import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'booking_provider.dart';
import 'report_provider.dart';

// MediPoints = 100 base + 50 per uploaded report + 30 per completed booking
final medipointsProvider = Provider<int>((ref) {
  final reportsCount =
      ref.watch(userReportsProvider).asData?.value.length ?? 0;
  final bookingsCount =
      ref.watch(userBookingsProvider).asData?.value.length ?? 0;
  return 100 + (reportsCount * 50) + (bookingsCount * 30);
});
