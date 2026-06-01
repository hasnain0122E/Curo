import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'booking_provider.dart';
import 'report_provider.dart';

// MediPoints: 50 per uploaded report + 30 per completed booking. Starts at 0.
final medipointsProvider = Provider<int>((ref) {
  final reportsCount = ref.watch(userReportsProvider).asData?.value.length ?? 0;
  final bookingsCount =
      ref.watch(userBookingsProvider).asData?.value.length ?? 0;
  return (reportsCount * 50) + (bookingsCount * 30);
});
