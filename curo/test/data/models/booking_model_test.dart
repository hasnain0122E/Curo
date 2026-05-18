import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curo/data/models/booking_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_document_snapshot.dart';

void main() {
  final bookingDate = DateTime(2024, 6, 20, 9, 0);
  final created = DateTime(2024, 6, 15);

  Map<String, dynamic> baseData({String status = 'upcoming'}) => {
        'userId': 'user_abc',
        'labId': 'lab_001',
        'labName': 'Chughtai Lab',
        'testName': 'CBC',
        'date': Timestamp.fromDate(bookingDate),
        'timeSlot': '9:00 AM',
        'priceRs': 650,
        'status': status,
        'createdAt': Timestamp.fromDate(created),
      };

  // ── isUpcoming ─────────────────────────────────────────────────────────────

  group('BookingModel.isUpcoming', () {
    test('true when status is upcoming', () {
      final b = BookingModel.fromFirestore(FakeDoc('b1', baseData()));
      expect(b.isUpcoming, isTrue);
    });

    test('false when status is completed', () {
      final b = BookingModel.fromFirestore(
          FakeDoc('b2', baseData(status: 'completed')));
      expect(b.isUpcoming, isFalse);
    });

    test('false when status is cancelled', () {
      final b = BookingModel.fromFirestore(
          FakeDoc('b3', baseData(status: 'cancelled')));
      expect(b.isUpcoming, isFalse);
    });
  });

  // ── fromFirestore ──────────────────────────────────────────────────────────

  group('BookingModel.fromFirestore', () {
    test('parses all fields correctly', () {
      final b = BookingModel.fromFirestore(FakeDoc('booking_1', baseData()));

      expect(b.id, 'booking_1');
      expect(b.userId, 'user_abc');
      expect(b.labId, 'lab_001');
      expect(b.labName, 'Chughtai Lab');
      expect(b.testName, 'CBC');
      expect(b.date, bookingDate);
      expect(b.timeSlot, '9:00 AM');
      expect(b.priceRs, 650);
      expect(b.status, 'upcoming');
      expect(b.createdAt, created);
    });

    test('defaults status to upcoming when missing', () {
      final data = Map<String, dynamic>.from(baseData())..remove('status');
      final b = BookingModel.fromFirestore(FakeDoc('b_def', data));
      expect(b.status, 'upcoming');
    });

    test('defaults priceRs to 0 when missing', () {
      final data = Map<String, dynamic>.from(baseData())..remove('priceRs');
      final b = BookingModel.fromFirestore(FakeDoc('b_price', data));
      expect(b.priceRs, 0);
    });
  });

  // ── toFirestore ────────────────────────────────────────────────────────────

  group('BookingModel.toFirestore', () {
    test('writes Timestamps for date and createdAt', () {
      final b = BookingModel.fromFirestore(FakeDoc('b1', baseData()));
      final map = b.toFirestore();

      expect(map['date'], isA<Timestamp>());
      expect(map['createdAt'], isA<Timestamp>());
      expect((map['date'] as Timestamp).toDate(), bookingDate);
      expect((map['createdAt'] as Timestamp).toDate(), created);
    });

    test('includes all required fields', () {
      final b = BookingModel.fromFirestore(FakeDoc('b1', baseData()));
      final map = b.toFirestore();

      expect(map.containsKey('userId'), isTrue);
      expect(map.containsKey('labId'), isTrue);
      expect(map.containsKey('labName'), isTrue);
      expect(map.containsKey('testName'), isTrue);
      expect(map.containsKey('status'), isTrue);
      expect(map.containsKey('priceRs'), isTrue);
    });
  });
}
