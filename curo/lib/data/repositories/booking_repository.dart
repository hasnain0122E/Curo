import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingRepository {
  BookingRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<BookingModel> get _bookings => _firestore
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
    final docRef = _bookings.doc();
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
    return _bookings
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<List<BookingModel>> getUserBookings(String userId) async {
    final snap = await _bookings
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _bookings.doc(bookingId).update({'status': status});
  }

  Future<void> cancelBooking(String bookingId) =>
      updateBookingStatus(bookingId, 'cancelled');
}
