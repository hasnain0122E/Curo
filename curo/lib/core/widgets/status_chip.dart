import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

enum StatusVariant { success, warning, danger, medipoints }

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.variant});

  final String label;
  final StatusVariant variant;

  // Status matrix — matches AppColors functional status token pairs
  static const _successBg = AppColors.successBackground; // #E8F5E9
  static const _successFg = AppColors.successForeground; // #2E7D32
  static const _warningBg = AppColors.warningBackground; // #FFF8E1
  static const _warningFg = AppColors.warningForeground; // #B78103
  static const _dangerBg = AppColors.dangerBackground; // #FFEBEE
  static const _dangerFg = AppColors.dangerForeground; // #C62828
  static const _medipointsBg = AppColors.medipointsBackground;
  static const _medipointsFg = AppColors.medipointsForeground;

  (Color, Color) _colors() => switch (variant) {
    StatusVariant.success => (_successBg, _successFg),
    StatusVariant.warning => (_warningBg, _warningFg),
    StatusVariant.danger => (_dangerBg, _dangerFg),
    StatusVariant.medipoints => (_medipointsBg, _medipointsFg),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
