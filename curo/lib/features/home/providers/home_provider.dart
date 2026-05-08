import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/lab_model.dart';
import '../../../data/models/report_model.dart';
import '../../../providers/lab_provider.dart';
import '../../../providers/report_provider.dart';

enum HealthRiskLevel { low, medium, high }

class HealthRiskData {
  const HealthRiskData({required this.level, required this.reportCount});
  final HealthRiskLevel level;
  final int reportCount;

  String get label => switch (level) {
        HealthRiskLevel.low => 'LOW',
        HealthRiskLevel.medium => 'MEDIUM',
        HealthRiskLevel.high => 'HIGH',
      };

  Color get color => switch (level) {
        HealthRiskLevel.low => const Color(0xFF22C55E),
        HealthRiskLevel.medium => const Color(0xFFF59E0B),
        HealthRiskLevel.high => const Color(0xFFEF4444),
      };

  double get gaugeProgress => switch (level) {
        HealthRiskLevel.low => 0.26,
        HealthRiskLevel.medium => 0.55,
        HealthRiskLevel.high => 0.85,
      };
}

class NearbyLab {
  const NearbyLab({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.rating,
    required this.fromPriceRs,
    required this.avatarColor,
  });
  final String id;
  final String name;
  final double distanceKm;
  final double rating;
  final int fromPriceRs;
  final Color avatarColor;
}

class RecentReport {
  const RecentReport({
    required this.id,
    required this.name,
    required this.date,
    required this.statusLabel,
    required this.status,
    required this.icon,
    required this.iconColor,
  });
  final String id;
  final String name;
  final String date;
  final String statusLabel;
  final StatusVariant status;
  final IconData icon;
  final Color iconColor;
}

// ── Helpers ────────────────────────────────────────────────────────────────────

const _avatarColors = [
  Color(0xFF1A5276),
  Color(0xFF154360),
  Color(0xFF0B5345),
  Color(0xFF4A235A),
  Color(0xFF1B4F72),
];

const _distancesKm = [1.2, 2.5, 3.1, 3.8, 4.5];

NearbyLab _toNearbyLab(LabModel lab, int index) => NearbyLab(
      id: lab.id,
      name: lab.name,
      distanceKm: _distancesKm[index % _distancesKm.length],
      rating: lab.rating,
      fromPriceRs: lab.startingPriceRs,
      avatarColor: _avatarColors[index % _avatarColors.length],
    );

RecentReport _toRecentReport(ReportModel r) {
  final summary = r.aiSummary?.toLowerCase() ?? '';
  StatusVariant variant;
  String label;
  if (summary.contains('critical') || summary.contains('abnormal')) {
    variant = StatusVariant.danger;
    label = 'Abnormal';
  } else if (summary.contains('attention') || summary.contains('borderline')) {
    variant = StatusVariant.warning;
    label = 'Review';
  } else {
    variant = StatusVariant.success;
    label = 'Normal';
  }

  final IconData icon;
  final Color iconColor;
  switch (r.category) {
    case 'X-Ray':
    case 'MRI':
      icon = Icons.medical_information_outlined;
      iconColor = const Color(0xFF8B5CF6);
    case 'ECG':
      icon = Icons.monitor_heart_outlined;
      iconColor = const Color(0xFFEF4444);
    case 'Blood Test':
      icon = Icons.bloodtype_outlined;
      iconColor = const Color(0xFF36BDF2);
    default:
      icon = Icons.assignment_outlined;
      iconColor = const Color(0xFF36BDF2);
  }

  return RecentReport(
    id: r.id,
    name: r.name,
    date: DateFormat('MMM d, yyyy').format(r.uploadedAt),
    statusLabel: label,
    status: variant,
    icon: icon,
    iconColor: iconColor,
  );
}

// ── Providers ──────────────────────────────────────────────────────────────────

final healthRiskProvider = Provider<HealthRiskData>((ref) {
  final reportsAsync = ref.watch(userReportsProvider);
  final count = reportsAsync.asData?.value.length ?? 0;
  final level = count >= 5
      ? HealthRiskLevel.low
      : count >= 2
          ? HealthRiskLevel.medium
          : HealthRiskLevel.high;
  return HealthRiskData(level: level, reportCount: count);
});

final nearbyLabsProvider = Provider<List<NearbyLab>>((ref) {
  final asyncLabs = ref.watch(labsStreamProvider);
  final models = asyncLabs.asData?.value ?? [];
  return [
    for (int i = 0; i < models.length; i++) _toNearbyLab(models[i], i),
  ];
});

final recentReportsProvider = Provider<List<RecentReport>>((ref) {
  final asyncReports = ref.watch(userReportsProvider);
  final models = asyncReports.asData?.value ?? [];
  return models.take(3).map(_toRecentReport).toList();
});
