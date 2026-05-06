import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';
import 'status_chip.dart';

enum LabResultStatus { normal, abnormal }

class CuroCard extends StatelessWidget {
  const CuroCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  }) : _highlighted = false;

  const CuroCard.highlighted({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  }) : _highlighted = true;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool _highlighted;

  static const _decoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.r16)),
    boxShadow: AppShadows.sm,
    border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
  );

  @override
  Widget build(BuildContext context) {
    final Widget card = _highlighted ? _highlightedCard() : _standardCard();
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }

  Widget _standardCard() => Container(
        decoration: _decoration,
        padding: padding ?? const EdgeInsets.all(AppSpacing.s16),
        child: child,
      );

  Widget _highlightedCard() => Container(
        decoration: _decoration,
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ColoredBox(
                color: AppColors.primary,
                child: SizedBox(width: 4),
              ),
              Expanded(
                child: Padding(
                  padding:
                      padding ?? const EdgeInsets.all(AppSpacing.s16),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      );
}

class LabResultCard extends StatelessWidget {
  const LabResultCard({
    super.key,
    required this.title,
    required this.date,
    required this.status,
    this.icon = Icons.science_outlined,
    this.onTap,
  });

  final String title;
  final String date;
  final LabResultStatus status;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CuroCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x1436BDF2),
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(date, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          StatusChip(
            label: status == LabResultStatus.normal ? 'Normal' : 'Abnormal',
            variant: status == LabResultStatus.normal
                ? StatusVariant.success
                : StatusVariant.danger,
          ),
          const SizedBox(width: AppSpacing.s4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
