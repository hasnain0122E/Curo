import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/lab_provider.dart';
import '../models/lab_booking_models.dart';

// ── Shared test catalog keyed by canonical test name ─────────────────────────
// Prices are approximate market rates in Pakistan (PKR).
// Each lab's Firestore document specifies which tests it offers via `tests` field.

const _kTestCatalog = <String, LabTest>{
  'Complete Blood Count': LabTest(
    id: 'cbc',
    name: 'Complete Blood Count',
    category: 'Blood',
    priceRs: 450,
    turnaroundHours: 4,
    icon: Icons.bloodtype_rounded,
  ),
  'Blood Sugar (Fasting)': LabTest(
    id: 'bsf',
    name: 'Blood Sugar (Fasting)',
    category: 'Blood',
    priceRs: 280,
    turnaroundHours: 2,
    icon: Icons.water_drop_rounded,
  ),
  'Lipid Profile': LabTest(
    id: 'lp',
    name: 'Lipid Profile',
    category: 'Blood',
    priceRs: 950,
    turnaroundHours: 6,
    icon: Icons.favorite_rounded,
  ),
  'Urine Complete Report': LabTest(
    id: 'ucr',
    name: 'Urine Complete Report',
    category: 'Urine',
    priceRs: 350,
    turnaroundHours: 3,
    icon: Icons.science_rounded,
  ),
  'Thyroid Function (TSH)': LabTest(
    id: 'tsh',
    name: 'Thyroid Function (TSH)',
    category: 'Blood',
    priceRs: 1200,
    turnaroundHours: 8,
    icon: Icons.biotech_rounded,
  ),
  'ECG 12-Lead': LabTest(
    id: 'ecg',
    name: 'ECG 12-Lead',
    category: 'Cardiology',
    priceRs: 600,
    turnaroundHours: 1,
    icon: Icons.monitor_heart_rounded,
  ),
  'HbA1c': LabTest(
    id: 'hba1c',
    name: 'HbA1c',
    category: 'Blood',
    priceRs: 900,
    turnaroundHours: 6,
    icon: Icons.water_drop_outlined,
  ),
  'Liver Function Test': LabTest(
    id: 'lft',
    name: 'Liver Function Test',
    category: 'Blood',
    priceRs: 1100,
    turnaroundHours: 6,
    icon: Icons.medical_services_rounded,
  ),
  'Kidney Function Test': LabTest(
    id: 'kft',
    name: 'Kidney Function Test',
    category: 'Blood',
    priceRs: 850,
    turnaroundHours: 5,
    icon: Icons.opacity_rounded,
  ),
  'COVID-19 PCR': LabTest(
    id: 'pcr',
    name: 'COVID-19 PCR',
    category: 'Virology',
    priceRs: 1500,
    turnaroundHours: 24,
    icon: Icons.coronavirus_rounded,
  ),
  'Dengue NS1 Antigen': LabTest(
    id: 'dengue',
    name: 'Dengue NS1 Antigen',
    category: 'Virology',
    priceRs: 1000,
    turnaroundHours: 4,
    icon: Icons.bug_report_rounded,
  ),
  'Hepatitis B Surface Antigen': LabTest(
    id: 'hbsag',
    name: 'Hepatitis B Surface Antigen',
    category: 'Serology',
    priceRs: 700,
    turnaroundHours: 5,
    icon: Icons.vaccines_rounded,
  ),
  'Hepatitis C Antibody': LabTest(
    id: 'hcv',
    name: 'Hepatitis C Antibody',
    category: 'Serology',
    priceRs: 700,
    turnaroundHours: 5,
    icon: Icons.vaccines_rounded,
  ),
  'Vitamin D': LabTest(
    id: 'vitd',
    name: 'Vitamin D',
    category: 'Blood',
    priceRs: 1800,
    turnaroundHours: 8,
    icon: Icons.wb_sunny_rounded,
  ),
  'Iron Studies': LabTest(
    id: 'iron',
    name: 'Iron Studies',
    category: 'Blood',
    priceRs: 750,
    turnaroundHours: 6,
    icon: Icons.circle_outlined,
  ),
};

// ── Providers ──────────────────────────────────────────────────────────────────

/// Returns tests offered by a specific lab, sourced from Firestore.
/// Falls back to all catalog tests if the lab has no `tests` list.
final labTestsProvider = Provider.family<List<LabTest>, String>((ref, labId) {
  final asyncLabs = ref.watch(labsStreamProvider);
  final lab = asyncLabs.asData?.value.where((l) => l.id == labId).firstOrNull;

  if (lab == null) return [];

  final offered = lab.tests;
  if (offered.isEmpty) return _kTestCatalog.values.toList();

  return offered
      .map((name) => _kTestCatalog[name])
      .whereType<LabTest>()
      .toList();
});

final labOpeningHoursProvider = Provider.family<String, String>((ref, labId) {
  final asyncLabs = ref.watch(labsStreamProvider);
  final lab = asyncLabs.asData?.value.where((l) => l.id == labId).firstOrNull;
  return lab?.openingHours ?? 'Mon–Sat: 8AM–8PM';
});
