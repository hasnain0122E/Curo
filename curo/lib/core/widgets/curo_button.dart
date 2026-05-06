import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

enum CuroButtonVariant { primary, secondary, text }

class CuroButton extends StatelessWidget {
  const CuroButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = CuroButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final CuroButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  @override
  Widget build(BuildContext context) => switch (variant) {
        CuroButtonVariant.primary => _primary(),
        CuroButtonVariant.secondary => _secondary(),
        CuroButtonVariant.text => _text(),
      };

  Widget _primary() => SizedBox(
        height: 52,
        width: width ?? double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0x8036BDF2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: _content(Colors.white),
        ),
      );

  Widget _secondary() => SizedBox(
        height: 52,
        width: width ?? double.infinity,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
          ),
          child: _content(AppColors.primary),
        ),
      );

  Widget _text() => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s4,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: _content(AppColors.primary),
      );

  Widget _content(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.s8),
          Text(label, style: AppTextStyles.button.copyWith(color: color)),
        ],
      );
    }
    return Text(label, style: AppTextStyles.button.copyWith(color: color));
  }
}
