import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/curo_button.dart';
import '../../../core/router/app_router.dart';
import '../models/medicine_models.dart';
import '../providers/medicine_provider.dart';

class ScannedMedicinesScreen extends ConsumerWidget {
  const ScannedMedicinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicineProvider);
    final notifier = ref.read(medicineProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Scan Results', style: AppTextStyles.h3),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.medicines),
            child: Text(
              'Done',
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.primary),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          // Success banner
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(AppRadius.r12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.30)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 20),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  '${state.scannedMedicines.length} medicines detected',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.success),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s16),

          // Medicine list
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.r12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < state.scannedMedicines.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: AppColors.border),
                  _MedicineRow(
                    medicine: state.scannedMedicines[i],
                    onToggle: () =>
                        notifier.toggleIncluded(state.scannedMedicines[i].id),
                    onEdit: () => _showEditDialog(
                      context,
                      state.scannedMedicines[i],
                      notifier,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s12),

          // Add manually button
          GestureDetector(
            onTap: () => _showAddDialog(context, notifier),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.r12),
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    'Add Medicine Manually',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.s20),

          // Smart Analysis card
          _SmartAnalysisCard(state: state),

          const SizedBox(height: AppSpacing.s20),

          CuroButton(
            label: 'Find Generic Alternatives',
            icon: Icons.auto_awesome_rounded,
            onPressed: () => context.go(AppRoutes.medicines),
          ),

          const SizedBox(height: AppSpacing.s16),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    ScannedMedicine medicine,
    MedicineNotifier notifier,
  ) async {
    final controller = TextEditingController(text: medicine.name);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Medicine', style: AppTextStyles.h3),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Medicine name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style:
                    AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              notifier.editName(medicine.id, controller.text);
              Navigator.pop(context);
            },
            child: Text('Save',
                style:
                    AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _showAddDialog(
    BuildContext context,
    MedicineNotifier notifier,
  ) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Medicine', style: AppTextStyles.h3),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Panadol 500mg',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style:
                    AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              notifier.addManually(controller.text);
              Navigator.pop(context);
            },
            child: Text('Add',
                style:
                    AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}

// ── Medicine Row ──────────────────────────────────────────────────────────────

class _MedicineRow extends StatelessWidget {
  const _MedicineRow({
    required this.medicine,
    required this.onToggle,
    required this.onEdit,
  });

  final ScannedMedicine medicine;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isUnclear = medicine.isUnclear;
    final isIncluded = medicine.isIncluded;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle icon
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: isUnclear
                    ? const Color(0xFFFFFBEB)
                    : isIncluded
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnclear
                      ? const Color(0xFFF59E0B)
                      : isIncluded
                          ? AppColors.success
                          : AppColors.danger,
                ),
              ),
              child: Icon(
                isUnclear
                    ? Icons.warning_amber_rounded
                    : isIncluded
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                size: 16,
                color: isUnclear
                    ? const Color(0xFFF59E0B)
                    : isIncluded
                        ? AppColors.success
                        : AppColors.danger,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),

          // Name + generic label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isIncluded
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    decoration:
                        isIncluded ? null : TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  medicine.genericLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isUnclear
                        ? const Color(0xFFF59E0B)
                        : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Edit icon
          GestureDetector(
            onTap: onEdit,
            child: const Padding(
              padding: EdgeInsets.only(left: AppSpacing.s8),
              child: Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Smart Analysis Card ───────────────────────────────────────────────────────

class _SmartAnalysisCard extends StatelessWidget {
  const _SmartAnalysisCard({required this.state});
  final MedicineState state;

  @override
  Widget build(BuildContext context) {
    final altCount =
        state.scannedMedicines.where((m) => m.isIncluded && !m.isUnclear).length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF8FE),
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'SMART ANALYSIS',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            "We've detected potential savings for $altCount of your "
            'medications by switching to generics.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textPrimary, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Monthly Savings',
                  value: '₨42.50',
                  valueColor: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: _StatBox(
                  label: 'Alternatives',
                  value: altCount.toString().padLeft(2, '0'),
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
