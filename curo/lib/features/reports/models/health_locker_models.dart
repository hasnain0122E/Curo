import 'package:flutter/material.dart';
import '../../../core/widgets/status_chip.dart';

enum ReportCategory { all, blood, urine, xray, ecg, other }

extension ReportCategoryX on ReportCategory {
  String get label => switch (this) {
        ReportCategory.all => 'All',
        ReportCategory.blood => 'Blood',
        ReportCategory.urine => 'Urine',
        ReportCategory.xray => 'X-Ray',
        ReportCategory.ecg => 'ECG',
        ReportCategory.other => 'Other',
      };
}

class LockerReport {
  const LockerReport({
    required this.id,
    required this.name,
    required this.date,
    required this.category,
    required this.statusLabel,
    required this.status,
    required this.icon,
    required this.iconColor,
  });

  final String id;
  final String name;
  final String date;
  final ReportCategory category;
  final String statusLabel;
  final StatusVariant status;
  final IconData icon;
  final Color iconColor;
}
