import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/lab_model.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/location_service.dart';
import '../../../providers/app_providers.dart';
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

// ── Avatar colors (deterministic, not positional) ────────────────────────────

const _avatarColors = [
  Color(0xFF1A5276),
  Color(0xFF154360),
  Color(0xFF0B5345),
  Color(0xFF4A235A),
  Color(0xFF1B4F72),
];

Color _avatarColor(String labId) =>
    _avatarColors[labId.hashCode.abs() % _avatarColors.length];

// ── Karachi city centre as fallback when location is unavailable ──────────────
const _fallbackLat = 24.8607;
const _fallbackLng = 67.0114;

NearbyLab _toNearbyLab(LabModel lab, double userLat, double userLng) {
  final dist = LocationService.distanceKm(userLat, userLng, lab.lat, lab.lng);
  return NearbyLab(
    id: lab.id,
    name: lab.name,
    distanceKm: double.parse(dist.toStringAsFixed(1)),
    rating: lab.rating,
    fromPriceRs: lab.startingPriceRs,
    avatarColor: _avatarColor(lab.id),
  );
}

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
  } else if (summary.isNotEmpty) {
    variant = StatusVariant.success;
    label = 'Normal';
  } else {
    variant = StatusVariant.warning;
    label = 'Pending';
  }

  final IconData icon;
  final Color iconColor;
  switch (r.category.toLowerCase()) {
    case 'x-ray':
    case 'mri':
      icon = Icons.medical_information_outlined;
      iconColor = const Color(0xFF8B5CF6);
    case 'ecg':
      icon = Icons.monitor_heart_outlined;
      iconColor = const Color(0xFFEF4444);
    case 'blood test':
    case 'blood':
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

// ── Recently-viewed labs (persisted via SharedPreferences) ────────────────────

class RecentlyViewedLabsNotifier extends Notifier<List<String>> {
  static const _key = 'recently_viewed_labs';
  static const _max = 10;

  @override
  List<String> build() {
    Future(() async {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getStringList(_key) ?? [];
    });
    return [];
  }

  Future<void> add(String id) async {
    final updated = [id, ...state.where((x) => x != id)].take(_max).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);
  }
}

final recentlyViewedLabsProvider =
    NotifierProvider<RecentlyViewedLabsNotifier, List<String>>(
        RecentlyViewedLabsNotifier.new);

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
  final location = ref.watch(userLocationProvider).asData?.value;
  final lat = location?.latitude ?? _fallbackLat;
  final lng = location?.longitude ?? _fallbackLng;

  final allLabs = models.map((lab) => _toNearbyLab(lab, lat, lng)).toList();
  final recentIds = ref.watch(recentlyViewedLabsProvider);

  // If user has previously visited labs, surface those first
  if (recentIds.isNotEmpty) {
    final labById = {for (final l in allLabs) l.id: l};
    final recent = recentIds
        .where(labById.containsKey)
        .map((id) => labById[id]!)
        .take(5)
        .toList();
    if (recent.isNotEmpty) return recent;
  }

  // Fall back to 5 nearest labs
  return (allLabs..sort((a, b) => a.distanceKm.compareTo(b.distanceKm)))
      .take(5)
      .toList();
});

final recentReportsProvider = Provider<List<RecentReport>>((ref) {
  final asyncReports = ref.watch(userReportsProvider);
  final models = asyncReports.asData?.value ?? [];
  return models.take(3).map(_toRecentReport).toList();
});
