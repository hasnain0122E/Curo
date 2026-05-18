import 'package:curo/features/labs/models/lab_booking_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── BookingStatus.label ────────────────────────────────────────────────────

  group('BookingStatusX.label', () {
    test('upcoming → "Upcoming"', () {
      expect(BookingStatus.upcoming.label, 'Upcoming');
    });
    test('completed → "Completed"', () {
      expect(BookingStatus.completed.label, 'Completed');
    });
    test('cancelled → "Cancelled"', () {
      expect(BookingStatus.cancelled.label, 'Cancelled');
    });
  });

  // ── BookingStatus.color ────────────────────────────────────────────────────

  group('BookingStatusX.color', () {
    test('upcoming uses CURO primary blue', () {
      expect(BookingStatus.upcoming.color, const Color(0xFF36BDF2));
    });
    test('completed uses green', () {
      expect(BookingStatus.completed.color, const Color(0xFF22C55E));
    });
    test('cancelled uses red', () {
      expect(BookingStatus.cancelled.color, const Color(0xFFEF4444));
    });
  });

  // ── TimeSlot ───────────────────────────────────────────────────────────────

  group('TimeSlot', () {
    test('stores id and label correctly', () {
      const slot = TimeSlot(id: 't1', label: '8:00 AM', isAvailable: true);
      expect(slot.id, 't1');
      expect(slot.label, '8:00 AM');
    });

    test('available slot has isAvailable = true', () {
      const slot = TimeSlot(id: 't1', label: '8:00 AM', isAvailable: true);
      expect(slot.isAvailable, isTrue);
    });

    test('unavailable slot has isAvailable = false', () {
      const slot = TimeSlot(id: 't4', label: '9:30 AM', isAvailable: false);
      expect(slot.isAvailable, isFalse);
    });
  });

  // ── kBookingTimeSlots ──────────────────────────────────────────────────────

  group('kBookingTimeSlots', () {
    test('contains exactly 14 time slots', () {
      expect(kBookingTimeSlots, hasLength(14));
    });

    test('all slot ids are unique', () {
      final ids = kBookingTimeSlots.map((s) => s.id).toSet();
      expect(ids.length, kBookingTimeSlots.length);
    });

    test('has both available and unavailable slots', () {
      final available = kBookingTimeSlots.where((s) => s.isAvailable);
      final unavailable = kBookingTimeSlots.where((s) => !s.isAvailable);
      expect(available, isNotEmpty);
      expect(unavailable, isNotEmpty);
    });

    test('first slot is 8:00 AM and is available', () {
      expect(kBookingTimeSlots.first.label, '8:00 AM');
      expect(kBookingTimeSlots.first.isAvailable, isTrue);
    });

    test('9:30 AM slot (t4) is unavailable', () {
      final t4 = kBookingTimeSlots.firstWhere((s) => s.id == 't4');
      expect(t4.isAvailable, isFalse);
    });
  });

  // ── LabTest ────────────────────────────────────────────────────────────────

  group('LabTest', () {
    test('stores fields correctly', () {
      const test_ = LabTest(
        id: 'lt1',
        name: 'Complete Blood Count',
        category: 'Haematology',
        priceRs: 650,
        turnaroundHours: 24,
        icon: Icons.bloodtype,
      );

      expect(test_.id, 'lt1');
      expect(test_.name, 'Complete Blood Count');
      expect(test_.category, 'Haematology');
      expect(test_.priceRs, 650);
      expect(test_.turnaroundHours, 24);
    });
  });

  // ── MyBooking ──────────────────────────────────────────────────────────────

  group('MyBooking', () {
    test('stores all fields correctly', () {
      final date = DateTime(2024, 6, 20, 9, 0);
      final booking = MyBooking(
        id: 'b1',
        labId: 'lab_001',
        labName: 'Chughtai Lab',
        labColor: Colors.blue,
        testName: 'CBC',
        date: date,
        timeSlot: '9:00 AM',
        priceRs: 650,
        status: BookingStatus.upcoming,
      );

      expect(booking.id, 'b1');
      expect(booking.labName, 'Chughtai Lab');
      expect(booking.testName, 'CBC');
      expect(booking.status, BookingStatus.upcoming);
      expect(booking.date, date);
    });
  });
}
