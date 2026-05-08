import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/status_chip.dart';
import '../models/health_locker_models.dart';

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

class HealthLockerNotifier extends Notifier<HealthLockerState> {
  @override
  HealthLockerState build() => HealthLockerState(reports: _mockReports);

  void selectCategory(ReportCategory cat) =>
      state = state.copyWith(selectedCategory: cat);

  void toggleView() => state = state.copyWith(isGridView: !state.isGridView);
}

final healthLockerProvider =
    NotifierProvider<HealthLockerNotifier, HealthLockerState>(
  HealthLockerNotifier.new,
);

const _mockReports = [
  LockerReport(
    id: '1',
    name: 'Complete Blood Count',
    date: 'Oct 24, 2023',
    category: ReportCategory.blood,
    statusLabel: 'NORMAL',
    status: StatusVariant.success,
    icon: Icons.water_drop_outlined,
    iconColor: Color(0xFF36BDF2),
  ),
  LockerReport(
    id: '2',
    name: 'Urine Analysis',
    date: 'Oct 20, 2023',
    category: ReportCategory.urine,
    statusLabel: 'ABNORMAL',
    status: StatusVariant.danger,
    icon: Icons.science_outlined,
    iconColor: Color(0xFFF59E0B),
  ),
  LockerReport(
    id: '3',
    name: 'Chest X-Ray',
    date: 'Oct 15, 2023',
    category: ReportCategory.xray,
    statusLabel: 'NORMAL',
    status: StatusVariant.success,
    icon: Icons.image_search_outlined,
    iconColor: Color(0xFF36BDF2),
  ),
  LockerReport(
    id: '4',
    name: 'ECG Report',
    date: 'Sep 28, 2023',
    category: ReportCategory.ecg,
    statusLabel: 'PENDING REVIEW',
    status: StatusVariant.warning,
    icon: Icons.monitor_heart_outlined,
    iconColor: Color(0xFF22C55E),
  ),
];
