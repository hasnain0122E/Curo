import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingRepository {
  BookingRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Subcollection path: users/{uid}/bookings
  CollectionReference<BookingModel> _bookingsOf(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('bookings')
      .withConverter<BookingModel>(
        fromFirestore: (snap, _) => BookingModel.fromFirestore(snap),
        toFirestore: (model, _) => model.toFirestore(),
      );

  Future<BookingModel> createBooking({
    required String userId,
    required String labId,
    required String labName,
    required String testName,
    required DateTime date,
    required String timeSlot,
    required int priceRs,
  }) async {
    final docRef = _bookingsOf(userId).doc();
    final booking = BookingModel(
      id: docRef.id,
      userId: userId,
      labId: labId,
      labName: labName,
      testName: testName,
      date: date,
      timeSlot: timeSlot,
      priceRs: priceRs,
      status: 'upcoming',
      createdAt: DateTime.now(),
    );
    await docRef.set(booking);
    return booking;
  }

  Stream<List<BookingModel>> watchUserBookings(String userId) {
    return _bookingsOf(userId).snapshots().map((snap) {
      final list = snap.docs.map((d) => d.data()).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<List<BookingModel>> getUserBookings(String userId) async {
    final snap = await _bookingsOf(userId).get();
    final list = snap.docs.map((d) => d.data()).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> updateBookingStatus(
    String userId,
    String bookingId,
    String status,
  ) async {
    await _bookingsOf(userId).doc(bookingId).update({'status': status});
  }

  Future<void> cancelBooking(String userId, String bookingId) =>
      updateBookingStatus(userId, bookingId, 'cancelled');
}
