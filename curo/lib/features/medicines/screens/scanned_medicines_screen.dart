import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/curo_button.dart';
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Prescription Results', style: AppTextStyles.h3),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.medicines),
            child: Text(
              'Done',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: state.scannedMedicines.isEmpty
          ? _buildEmptyState(context)
          : _buildResults(context, state, notifier),
    );
  }

  Widget _buildResults(
    BuildContext context,
    MedicineState state,
    MedicineNotifier notifier,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        // ── Detection banner ────────────────────────────────────────────────
        _DetectedBanner(count: state.scannedMedicines.length),

        const SizedBox(height: AppSpacing.s16),

        // ── Per-medicine: prescribed card + horizontal alternatives ─────────
        for (final medicine in state.scannedMedicines) ...[
          _MedicineEntry(
            medicine: medicine,
            onToggle: () => notifier.toggleIncluded(medicine.id),
            onEdit: () => _showEditDialog(context, medicine, notifier),
          ),
          const SizedBox(height: AppSpacing.s16),
        ],

        // ── Add manually ────────────────────────────────────────────────────
        _AddManuallyTile(onTap: () => _showAddDialog(context, notifier)),

        const SizedBox(height: AppSpacing.s24),

        // ── CTA ─────────────────────────────────────────────────────────────
        CuroButton(
          label: 'Search Medicine Finder',
          icon: Icons.search_rounded,
          onPressed: () => context.go(AppRoutes.medicines),
        ),

        const SizedBox(height: AppSpacing.s16),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.medication_outlined,
              size: 56,
              color: AppColors.border,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text('No medicines detected', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Try a clearer photo or enter medicines manually.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s32),
            CuroButton(
              label: 'Browse Medicine Finder',
              icon: Icons.search_rounded,
              onPressed: () => context.go(AppRoutes.medicines),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit dialog ───────────────────────────────────────────────────────────────

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
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              notifier.editName(medicine.id, controller.text);
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  // ── Add dialog ────────────────────────────────────────────────────────────────

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
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              notifier.addManually(controller.text);
              Navigator.pop(context);
            },
            child: Text(
              'Add',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}

// ── Detection banner ──────────────────────────────────────────────────────────

class _DetectedBanner extends StatelessWidget {
  const _DetectedBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(
          color: AppColors.successForeground.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.successForeground,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            '$count medicine${count == 1 ? '' : 's'} detected from prescription',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.successForeground,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Medicine entry (card + horizontal alternatives) ───────────────────────────

class _MedicineEntry extends StatelessWidget {
  const _MedicineEntry({
    required this.medicine,
    required this.onToggle,
    required this.onEdit,
  });

  final ScannedMedicine medicine;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PrescriptionCard(
          medicine: medicine,
          onToggle: onToggle,
          onEdit: onEdit,
        ),
        if (medicine.alternatives.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          _AlternativesRow(alternatives: medicine.alternatives),
        ],
      ],
    );
  }
}

// ── Prescription card ─────────────────────────────────────────────────────────

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
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

    final statusColor = isUnclear
        ? AppColors.warningForeground
        : isIncluded
        ? AppColors.primary
        : AppColors.dangerForeground;

    final statusBg = isUnclear
        ? AppColors.warningBackground
        : isIncluded
        ? AppColors.primary.withValues(alpha: 0.08)
        : AppColors.dangerBackground;

    final statusIcon = isUnclear
        ? Icons.warning_amber_rounded
        : isIncluded
        ? Icons.medication_rounded
        : Icons.close_rounded;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status / toggle button
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: statusBg,
                shape: BoxShape.circle,
                border: Border.all(color: statusColor),
              ),
              child: Icon(statusIcon, size: 18, color: statusColor),
            ),
          ),

          const SizedBox(width: AppSpacing.s12),

          // Medicine name + generic + form
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
                    decoration: isIncluded ? null : TextDecoration.lineThrough,
                  ),
                ),
                if (medicine.genericLabel.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    medicine.genericLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (medicine.form.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.category_outlined,
                        size: 11,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        medicine.form,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Edit
          GestureDetector(
            onTap: onEdit,
            child: const Padding(
              padding: EdgeInsets.only(left: AppSpacing.s8),
              child: Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alternatives row ──────────────────────────────────────────────────────────

class _AlternativesRow extends StatelessWidget {
  const _AlternativesRow({required this.alternatives});
  final List<GenericAlternative> alternatives;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(
              Icons.swap_horiz_rounded,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Cheaper alternatives',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            Text(
              'scroll ▸',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.s8),

        // Horizontal card list
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: AppSpacing.s4),
            itemCount: alternatives.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
            itemBuilder: (_, i) => _AlternativeCard(alt: alternatives[i]),
          ),
        ),
      ],
    );
  }
}

// ── Alternative card ──────────────────────────────────────────────────────────

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({required this.alt});
  final GenericAlternative alt;

  @override
  Widget build(BuildContext context) {
    final hasSaving = alt.savingNote.isNotEmpty;
    return Container(
      width: 140,
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: hasSaving ? AppColors.successBackground : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(
          color: hasSaving
              ? AppColors.successForeground.withValues(alpha: 0.22)
              : AppColors.border,
        ),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saving pill at top when applicable
          if (hasSaving) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.successForeground.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.r24),
                border: Border.all(
                  color: AppColors.successForeground.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                alt.savingNote,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.successForeground,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
          ],

          // Brand name
          Text(
            alt.brandName,
            style: AppTextStyles.labelLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Manufacturer
          Text(
            alt.manufacturer,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // Price
          Text(
            'Rs ${alt.priceRs}',
            style: AppTextStyles.h3.copyWith(
              color: hasSaving
                  ? AppColors.successForeground
                  : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add manually tile ─────────────────────────────────────────────────────────

class _AddManuallyTile extends StatelessWidget {
  const _AddManuallyTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.s8),
            Text(
              'Add Medicine Manually',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
