import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/lab_provider.dart';
import '../models/lab_booking_models.dart';

// ── Mock test catalogs per lab ─────────────────────────────────────────────────

const _apolloTests = <LabTest>[
  LabTest(id: 'a1', name: 'Complete Blood Count', category: 'Blood', priceRs: 450, turnaroundHours: 4, icon: Icons.bloodtype_rounded),
  LabTest(id: 'a2', name: 'Blood Sugar (Fasting)', category: 'Blood', priceRs: 280, turnaroundHours: 2, icon: Icons.water_drop_rounded),
  LabTest(id: 'a3', name: 'Lipid Profile', category: 'Blood', priceRs: 950, turnaroundHours: 6, icon: Icons.favorite_rounded),
  LabTest(id: 'a4', name: 'Urine Complete Report', category: 'Urine', priceRs: 350, turnaroundHours: 3, icon: Icons.science_rounded),
  LabTest(id: 'a5', name: 'Thyroid Function (TSH)', category: 'Blood', priceRs: 1200, turnaroundHours: 8, icon: Icons.biotech_rounded),
  LabTest(id: 'a6', name: 'ECG 12-Lead', category: 'Cardiology', priceRs: 600, turnaroundHours: 1, icon: Icons.monitor_heart_rounded),
];

const _metropolisTests = <LabTest>[
  LabTest(id: 'm1', name: 'Complete Blood Count', category: 'Blood', priceRs: 890, turnaroundHours: 4, icon: Icons.bloodtype_rounded),
  LabTest(id: 'm2', name: 'Blood Sugar (Fasting)', category: 'Blood', priceRs: 600, turnaroundHours: 2, icon: Icons.water_drop_rounded),
  LabTest(id: 'm3', name: 'Lipid Profile', category: 'Blood', priceRs: 1800, turnaroundHours: 6, icon: Icons.favorite_rounded),
  LabTest(id: 'm4', name: 'Urine Complete Report', category: 'Urine', priceRs: 700, turnaroundHours: 3, icon: Icons.science_rounded),
  LabTest(id: 'm5', name: 'Thyroid Function (TSH)', category: 'Blood', priceRs: 2400, turnaroundHours: 8, icon: Icons.biotech_rounded),
  LabTest(id: 'm6', name: 'ECG 12-Lead', category: 'Cardiology', priceRs: 1100, turnaroundHours: 1, icon: Icons.monitor_heart_rounded),
];

const _chughtaiTests = <LabTest>[
  LabTest(id: 'c1', name: 'Complete Blood Count', category: 'Blood', priceRs: 1200, turnaroundHours: 3, icon: Icons.bloodtype_rounded),
  LabTest(id: 'c2', name: 'Blood Sugar (Fasting)', category: 'Blood', priceRs: 800, turnaroundHours: 2, icon: Icons.water_drop_rounded),
  LabTest(id: 'c3', name: 'Lipid Profile', category: 'Blood', priceRs: 2400, turnaroundHours: 5, icon: Icons.favorite_rounded),
  LabTest(id: 'c4', name: 'Urine Complete Report', category: 'Urine', priceRs: 900, turnaroundHours: 3, icon: Icons.science_rounded),
  LabTest(id: 'c5', name: 'Thyroid Function (TSH)', category: 'Blood', priceRs: 3200, turnaroundHours: 6, icon: Icons.biotech_rounded),
  LabTest(id: 'c6', name: 'ECG 12-Lead', category: 'Cardiology', priceRs: 1500, turnaroundHours: 1, icon: Icons.monitor_heart_rounded),
];

const _essaTests = <LabTest>[
  LabTest(id: 'e1', name: 'Complete Blood Count', category: 'Blood', priceRs: 350, turnaroundHours: 5, icon: Icons.bloodtype_rounded),
  LabTest(id: 'e2', name: 'Blood Sugar (Fasting)', category: 'Blood', priceRs: 250, turnaroundHours: 2, icon: Icons.water_drop_rounded),
  LabTest(id: 'e3', name: 'Lipid Profile', category: 'Blood', priceRs: 750, turnaroundHours: 8, icon: Icons.favorite_rounded),
  LabTest(id: 'e4', name: 'Urine Complete Report', category: 'Urine', priceRs: 300, turnaroundHours: 3, icon: Icons.science_rounded),
  LabTest(id: 'e5', name: 'Thyroid Function (TSH)', category: 'Blood', priceRs: 900, turnaroundHours: 10, icon: Icons.biotech_rounded),
  LabTest(id: 'e6', name: 'ECG 12-Lead', category: 'Cardiology', priceRs: 500, turnaroundHours: 1, icon: Icons.monitor_heart_rounded),
];

const _aghaKhanTests = <LabTest>[
  LabTest(id: 'k1', name: 'Complete Blood Count', category: 'Blood', priceRs: 750, turnaroundHours: 3, icon: Icons.bloodtype_rounded),
  LabTest(id: 'k2', name: 'Blood Sugar (Fasting)', category: 'Blood', priceRs: 500, turnaroundHours: 2, icon: Icons.water_drop_rounded),
  LabTest(id: 'k3', name: 'Lipid Profile', category: 'Blood', priceRs: 1500, turnaroundHours: 5, icon: Icons.favorite_rounded),
  LabTest(id: 'k4', name: 'Urine Complete Report', category: 'Urine', priceRs: 600, turnaroundHours: 3, icon: Icons.science_rounded),
  LabTest(id: 'k5', name: 'Thyroid Function (TSH)', category: 'Blood', priceRs: 2000, turnaroundHours: 6, icon: Icons.biotech_rounded),
  LabTest(id: 'k6', name: 'ECG 12-Lead', category: 'Cardiology', priceRs: 900, turnaroundHours: 1, icon: Icons.monitor_heart_rounded),
];

const _labTestsMap = <String, List<LabTest>>{
  'lab_001': _apolloTests,
  'lab_002': _chughtaiTests,
  'lab_003': _metropolisTests,
  'lab_004': _essaTests,
  'lab_005': _aghaKhanTests,
};

// ── Providers ──────────────────────────────────────────────────────────────────

final labTestsProvider = Provider.family<List<LabTest>, String>((ref, labId) {
  return _labTestsMap[labId] ?? _apolloTests;
});

final labOpeningHoursProvider =
    Provider.family<String, String>((ref, labId) {
  final asyncLabs = ref.watch(labsStreamProvider);
  final lab = asyncLabs.asData?.value
      .where((l) => l.id == labId)
      .firstOrNull;
  return lab?.openingHours ?? 'Mon–Sat: 8AM–8PM';
});

final myBookingsProvider =
    NotifierProvider<MyBookingsNotifier, List<MyBooking>>(MyBookingsNotifier.new);

class MyBookingsNotifier extends Notifier<List<MyBooking>> {
  @override
  List<MyBooking> build() {
    final now = DateTime.now();
    return [
      MyBooking(
        id: 'b1',
        labId: 'lab_001',
        labName: 'Apollo Diagnostics',
        labColor: const Color(0xFF1A5276),
        testName: 'Complete Blood Count',
        date: now.add(const Duration(days: 1)),
        timeSlot: '9:00 AM',
        priceRs: 450,
        status: BookingStatus.upcoming,
      ),
      MyBooking(
        id: 'b2',
        labId: 'lab_002',
        labName: 'Chughtai Lab',
        labColor: const Color(0xFF154360),
        testName: 'ECG 12-Lead',
        date: now.add(const Duration(days: 3)),
        timeSlot: '10:30 AM',
        priceRs: 1500,
        status: BookingStatus.upcoming,
      ),
      MyBooking(
        id: 'b3',
        labId: 'lab_003',
        labName: 'Excel Labs',
        labColor: const Color(0xFF0B5345),
        testName: 'Lipid Profile',
        date: now.subtract(const Duration(days: 7)),
        timeSlot: '8:30 AM',
        priceRs: 1800,
        status: BookingStatus.completed,
      ),
      MyBooking(
        id: 'b4',
        labId: 'lab_004',
        labName: 'Dr. Essa Laboratory',
        labColor: const Color(0xFF4A235A),
        testName: 'Blood Sugar (Fasting)',
        date: now.subtract(const Duration(days: 14)),
        timeSlot: '8:00 AM',
        priceRs: 250,
        status: BookingStatus.completed,
      ),
      MyBooking(
        id: 'b5',
        labId: 'lab_005',
        labName: 'Aga Khan Lab',
        labColor: const Color(0xFF1B4F72),
        testName: 'Thyroid Function (TSH)',
        date: now.subtract(const Duration(days: 30)),
        timeSlot: '9:30 AM',
        priceRs: 2000,
        status: BookingStatus.cancelled,
      ),
    ];
  }

  void add(MyBooking booking) => state = [booking, ...state];
}
