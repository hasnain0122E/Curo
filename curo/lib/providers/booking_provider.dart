import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking_model.dart';
import 'app_providers.dart';

// ── Live bookings stream ──────────────────────────────────────────────────────

final userBookingsProvider =
    StreamProvider.autoDispose<List<BookingModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) return Stream.value([]);
  return ref.watch(bookingRepositoryProvider).watchUserBookings(user.uid);
});

// ── Create booking state ──────────────────────────────────────────────────────

class BookingCreateState {
  const BookingCreateState({
    this.isLoading = false,
    this.error,
    this.created,
  });
  final bool isLoading;
  final String? error;
  final BookingModel? created;
}

class BookingCreateNotifier extends Notifier<BookingCreateState> {
  @override
  BookingCreateState build() => const BookingCreateState();

  Future<BookingModel?> createBooking({
    required String labId,
    required String labName,
    required String testName,
    required DateTime date,
    required String timeSlot,
    required int priceRs,
  }) async {
    final user = ref.read(authStateChangesProvider).asData?.value;
    if (user == null) {
      state = const BookingCreateState(error: 'Not signed in.');
      return null;
    }
    state = const BookingCreateState(isLoading: true);
    try {
      final booking = await ref.read(bookingRepositoryProvider).createBooking(
            userId: user.uid,
            labId: labId,
            labName: labName,
            testName: testName,
            date: date,
            timeSlot: timeSlot,
            priceRs: priceRs,
          );
      state = BookingCreateState(created: booking);
      return booking;
    } on FirebaseException catch (e) {
      state = BookingCreateState(error: e.message ?? 'Booking failed.');
      return null;
    } catch (e) {
      state = BookingCreateState(error: e.toString());
      return null;
    }
  }

  Future<void> cancel(String bookingId) async {
    final user = ref.read(authStateChangesProvider).asData?.value;
    if (user == null) return;
    await ref.read(bookingRepositoryProvider).cancelBooking(user.uid, bookingId);
  }
}

final bookingCreateProvider =
    NotifierProvider<BookingCreateNotifier, BookingCreateState>(
        BookingCreateNotifier.new);
