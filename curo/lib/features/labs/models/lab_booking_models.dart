import 'package:flutter/material.dart';

class LabTest {
  const LabTest({
    required this.id,
    required this.name,
    required this.category,
    required this.priceRs,
    required this.turnaroundHours,
    required this.icon,
  });

  final String id;
  final String name;
  final String category;
  final int priceRs;
  final int turnaroundHours;
  final IconData icon;
}

class TimeSlot {
  const TimeSlot({
    required this.id,
    required this.label,
    required this.isAvailable,
  });

  final String id;
  final String label;
  final bool isAvailable;
}

const kBookingTimeSlots = <TimeSlot>[
  TimeSlot(id: 't1', label: '8:00 AM', isAvailable: true),
  TimeSlot(id: 't2', label: '8:30 AM', isAvailable: true),
  TimeSlot(id: 't3', label: '9:00 AM', isAvailable: true),
  TimeSlot(id: 't4', label: '9:30 AM', isAvailable: false),
  TimeSlot(id: 't5', label: '10:00 AM', isAvailable: true),
  TimeSlot(id: 't6', label: '10:30 AM', isAvailable: true),
  TimeSlot(id: 't7', label: '11:00 AM', isAvailable: false),
  TimeSlot(id: 't8', label: '11:30 AM', isAvailable: true),
  TimeSlot(id: 't9', label: '12:00 PM', isAvailable: true),
  TimeSlot(id: 't10', label: '2:00 PM', isAvailable: true),
  TimeSlot(id: 't11', label: '2:30 PM', isAvailable: true),
  TimeSlot(id: 't12', label: '3:00 PM', isAvailable: false),
  TimeSlot(id: 't13', label: '3:30 PM', isAvailable: true),
  TimeSlot(id: 't14', label: '4:00 PM', isAvailable: true),
];

enum BookingStatus { upcoming, completed, cancelled }

extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
        BookingStatus.upcoming => 'Upcoming',
        BookingStatus.completed => 'Completed',
        BookingStatus.cancelled => 'Cancelled',
      };

  Color get color => switch (this) {
        BookingStatus.upcoming => const Color(0xFF36BDF2),
        BookingStatus.completed => const Color(0xFF22C55E),
        BookingStatus.cancelled => const Color(0xFFEF4444),
      };
}

class MyBooking {
  MyBooking({
    required this.id,
    required this.labId,
    required this.labName,
    required this.labColor,
    required this.testName,
    required this.date,
    required this.timeSlot,
    required this.priceRs,
    required this.status,
  });

  final String id;
  final String labId;
  final String labName;
  final Color labColor;
  final String testName;
  final DateTime date;
  final String timeSlot;
  final int priceRs;
  final BookingStatus status;
}
