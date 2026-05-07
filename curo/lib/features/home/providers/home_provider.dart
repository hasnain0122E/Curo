import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/status_chip.dart';

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

// ── Mock providers ─────────────────────────────────────────────────────────────

final healthRiskProvider = Provider<HealthRiskData>(
  (_) => const HealthRiskData(level: HealthRiskLevel.low, reportCount: 3),
);

final nearbyLabsProvider = Provider<List<NearbyLab>>(
  (_) => const [
    NearbyLab(
      id: '1',
      name: 'Apollo Diagnostics',
      distanceKm: 1.2,
      rating: 4.8,
      fromPriceRs: 500,
      avatarColor: Color(0xFF1A5276),
    ),
    NearbyLab(
      id: '2',
      name: 'Thyrocare Lab',
      distanceKm: 2.5,
      rating: 4.3,
      fromPriceRs: 450,
      avatarColor: Color(0xFF154360),
    ),
    NearbyLab(
      id: '3',
      name: 'Chughtai Lab',
      distanceKm: 3.1,
      rating: 4.6,
      fromPriceRs: 650,
      avatarColor: Color(0xFF0B5345),
    ),
  ],
);

final recentReportsProvider = Provider<List<RecentReport>>(
  (_) => const [
    RecentReport(
      id: '1',
      name: 'Full Body Checkup',
      date: 'Oct 24, 2023',
      statusLabel: 'Normal',
      status: StatusVariant.success,
      icon: Icons.assignment_outlined,
      iconColor: Color(0xFF36BDF2),
    ),
    RecentReport(
      id: '2',
      name: 'CBC & Diabetes',
      date: 'Sep 15, 2023',
      statusLabel: 'Normal',
      status: StatusVariant.success,
      icon: Icons.monitor_heart_outlined,
      iconColor: Color(0xFF36BDF2),
    ),
  ],
);
