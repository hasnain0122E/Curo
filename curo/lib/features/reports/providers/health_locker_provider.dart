import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/report_model.dart';
import '../../../providers/report_provider.dart';
import '../models/health_locker_models.dart';

// ── ReportModel → LockerReport mapping ───────────────────────────────────────

ReportCategory _categoryFrom(String raw) {
  switch (raw.toLowerCase()) {
    case 'blood test':
    case 'blood':
      return ReportCategory.blood;
    case 'urine':
      return ReportCategory.urine;
    case 'x-ray':
    case 'xray':
    case 'mri':
      return ReportCategory.xray;
    case 'ecg':
      return ReportCategory.ecg;
    default:
      return ReportCategory.other;
  }
}

LockerReport _toLockerReport(ReportModel r) {
  final cat = _categoryFrom(r.category);
  final summary = (r.aiSummary ?? '').toLowerCase();

  final StatusVariant variant;
  final String statusLabel;
  if (summary.isEmpty) {
    variant = StatusVariant.warning;
    statusLabel = 'PENDING';
  } else if (summary.contains('critical') ||
      summary.contains('abnormal') ||
      summary.contains('high') ||
      summary.contains('danger')) {
    variant = StatusVariant.danger;
    statusLabel = 'ABNORMAL';
  } else if (summary.contains('review') ||
      summary.contains('attention') ||
      summary.contains('borderline')) {
    variant = StatusVariant.warning;
    statusLabel = 'REVIEW';
  } else {
    variant = StatusVariant.success;
    statusLabel = 'NORMAL';
  }

  final IconData icon;
  final Color iconColor;
  switch (cat) {
    case ReportCategory.blood:
      icon = Icons.bloodtype_outlined;
      iconColor = const Color(0xFF36BDF2);
    case ReportCategory.urine:
      icon = Icons.science_outlined;
      iconColor = const Color(0xFFF59E0B);
    case ReportCategory.xray:
      icon = Icons.image_search_outlined;
      iconColor = const Color(0xFF8B5CF6);
    case ReportCategory.ecg:
      icon = Icons.monitor_heart_outlined;
      iconColor = const Color(0xFF22C55E);
    default:
      icon = Icons.assignment_outlined;
      iconColor = const Color(0xFF36BDF2);
  }

  return LockerReport(
    id: r.id,
    name: r.name,
    date: DateFormat('MMM d, yyyy').format(r.uploadedAt),
    category: cat,
    statusLabel: statusLabel,
    status: variant,
    icon: icon,
    iconColor: iconColor,
  );
}

// ── State ─────────────────────────────────────────────────────────────────────

class HealthLockerState {
  const HealthLockerState({
    this.selectedCategory = ReportCategory.all,
    this.isGridView = true,
    this.reports = const [],
  });

  final ReportCategory selectedCategory;
  final bool isGridView;
  final List<LockerReport> reports;

  List<LockerReport> get filtered => selectedCategory == ReportCategory.all
      ? reports
      : reports.where((r) => r.category == selectedCategory).toList();

  HealthLockerState copyWith({
    ReportCategory? selectedCategory,
    bool? isGridView,
    List<LockerReport>? reports,
  }) =>
      HealthLockerState(
        selectedCategory: selectedCategory ?? this.selectedCategory,
        isGridView: isGridView ?? this.isGridView,
        reports: reports ?? this.reports,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class HealthLockerNotifier extends Notifier<HealthLockerState> {
  ReportCategory _selectedCategory = ReportCategory.all;
  bool _isGridView = true;

  @override
  HealthLockerState build() {
    final reportsAsync = ref.watch(userReportsProvider);
    final models = reportsAsync.asData?.value ?? [];
    final lockerReports = models.map(_toLockerReport).toList();
    return HealthLockerState(
      selectedCategory: _selectedCategory,
      isGridView: _isGridView,
      reports: lockerReports,
    );
  }

  void selectCategory(ReportCategory cat) {
    _selectedCategory = cat;
    state = state.copyWith(selectedCategory: cat);
  }

  void toggleView() {
    _isGridView = !_isGridView;
    state = state.copyWith(isGridView: _isGridView);
  }
}

final healthLockerProvider =
    NotifierProvider<HealthLockerNotifier, HealthLockerState>(
  HealthLockerNotifier.new,
);
