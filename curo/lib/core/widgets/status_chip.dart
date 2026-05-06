import 'package:flutter/material.dart';
import '../constants/app_text_styles.dart';

enum StatusVariant { success, warning, danger, medipoints }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.variant,
  });

  final String label;
  final StatusVariant variant;

  // Pre-computed hex alphas: 0.12*255≈31=0x1F, 0.15*255≈38=0x26
  static const _successBg = Color(0x1F22C55E);
  static const _successFg = Color(0xFF16A34A);
  static const _warningBg = Color(0x1FF59E0B);
  static const _warningFg = Color(0xFFD97706);
  static const _dangerBg = Color(0x1FEF4444);
  static const _dangerFg = Color(0xFFDC2626);
  static const _medipointsBg = Color(0x26EAB308);
  static const _medipointsFg = Color(0xFFCA8A04);

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
