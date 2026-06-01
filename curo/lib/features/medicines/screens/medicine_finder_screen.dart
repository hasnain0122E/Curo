import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/curo_bottom_nav_bar.dart';
import '../../../core/router/app_router.dart';
import '../models/medicine_models.dart';
import '../providers/medicine_provider.dart';

class MedicineFinderScreen extends ConsumerStatefulWidget {
  const MedicineFinderScreen({super.key});

  @override
  ConsumerState<MedicineFinderScreen> createState() =>
      _MedicineFinderScreenState();
}

class _MedicineFinderScreenState extends ConsumerState<MedicineFinderScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavTap(int i) {
    if (i == 0) context.go(AppRoutes.home);
    if (i == 1) context.go(AppRoutes.labs);
    if (i == 2) context.go(AppRoutes.reports);
    if (i == 4) context.go(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medicineProvider);
    final notifier = ref.read(medicineProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text('Medicine Finder', style: AppTextStyles.h3),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.medicineScanner),
            icon: const Icon(
              Icons.document_scanner_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            tooltip: 'Scan Prescription',
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
          // Search bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.r24),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.sm,
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.s16),
                const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: notifier.searchMedicine,
                    textInputAction: TextInputAction.search,
                    onSubmitted: notifier.searchMedicine,
                    decoration: InputDecoration(
                      hintText: 'Search branded or generic medicine...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                if (state.searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      notifier.resetSearch();
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: AppSpacing.s12),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: AppSpacing.s16),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s20),

          // Recent searches
          Text('Recent Searches', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.s12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.recentSearches.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
              itemBuilder: (_, i) {
                final label = state.recentSearches[i];
                final isActive =
                    state.searchQuery.toLowerCase() == label.toLowerCase();
                return GestureDetector(
                  onTap: () {
                    _searchController.text = label;
                    notifier.selectRecent(label);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                      border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive
                              ? Icons.search_rounded
                              : Icons.history_rounded,
                          size: 12,
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading indicator
          if (state.isSearching) ...[
            const SizedBox(height: AppSpacing.s48),
            const Center(child: CircularProgressIndicator()),
          ]
          // Comparison cards (shown when there's a result)
          else if (state.comparison != null) ...[
            const SizedBox(height: AppSpacing.s24),
            _ComparisonModule(comparison: state.comparison!),
            const SizedBox(height: AppSpacing.s24),
            _FindPharmaciesButton(comparison: state.comparison!),
            const SizedBox(height: AppSpacing.s16),
            _PharmacyAvailabilityRow(comparison: state.comparison!),
          ] else if (state.searchQuery.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s48),
            _EmptyResult(query: state.searchQuery),
          ] else ...[
            const SizedBox(height: AppSpacing.s32),
            _ScanPromptCard(
              onTap: () => context.push(AppRoutes.medicineScanner),
            ),
            const SizedBox(height: AppSpacing.s12),
            _LabScanPromptCard(
              onTap: () => context.push(AppRoutes.labTestScanner),
            ),
          ],

          const SizedBox(height: AppSpacing.s16),
        ],
      ),
      bottomNavigationBar: CuroBottomNavBar(currentIndex: 3, onTap: _onNavTap),
    );
  }
}

// ── Comparison Module — split-screen brand vs generic ─────────────────────────

class _ComparisonModule extends StatelessWidget {
  const _ComparisonModule({required this.comparison});
  final MedicineComparison comparison;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.md,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _BrandedPanel(comparison: comparison)),
            _VsDivider(),
            Expanded(child: _GenericPanel(comparison: comparison)),
          ],
        ),
      ),
    );
  }
}

class _BrandedPanel extends StatelessWidget {
  const _BrandedPanel({required this.comparison});
  final MedicineComparison comparison;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + FULL PRICE tag row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.dangerBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: AppColors.dangerForeground,
                  size: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.r24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'FULL PRICE',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            comparison.brandedName,
            style: AppTextStyles.h3,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            comparison.brandedMaker,
            style: AppTextStyles.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (comparison.brandedForm.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              comparison.brandedForm,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (comparison.prescriptionRequired) ...[
            const SizedBox(height: AppSpacing.s8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(AppRadius.r24),
              ),
              child: Text(
                'Rx',
                style: AppTextStyles.labelSmall.copyWith(
                  color: const Color(0xFF7C3AED),
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            'Full Price',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Rs ${comparison.brandedPriceRs}',
            style: AppTextStyles.h2.copyWith(color: AppColors.dangerForeground),
          ),
        ],
      ),
    );
  }
}

class _GenericPanel extends StatelessWidget {
  const _GenericPanel({required this.comparison});
  final MedicineComparison comparison;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.successBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + SAVE pill row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.successForeground.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.successForeground,
                    size: 18,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successForeground.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.r24),
                    border: Border.all(
                      color: AppColors.successForeground.withValues(
                        alpha: 0.25,
                      ),
                    ),
                  ),
                  child: Text(
                    comparison.savingsPercent > 0
                        ? 'SAVE ${comparison.savingsPercent}%'
                        : 'GENERIC',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.successForeground,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              comparison.genericName,
              style: AppTextStyles.h3,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              comparison.genericDesc,
              style: AppTextStyles.bodySmall.copyWith(
                height: 1.5,
                color: AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              'Estimated Price',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.successForeground.withValues(alpha: 0.70),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Rs ${comparison.genericPriceRs}',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.successForeground,
              ),
            ),
            if (comparison.priceDiffPercent > 0) ...[
              const SizedBox(height: 2),
              Text(
                '${comparison.priceDiffPercent}% less than branded',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.successForeground,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VsDivider extends StatelessWidget {
  const _VsDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Center(child: Container(width: 1, color: AppColors.border)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.r4),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'VS',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Find Pharmacies Button ────────────────────────────────────────────────────

class _FindPharmaciesButton extends StatelessWidget {
  const _FindPharmaciesButton({required this.comparison});
  final MedicineComparison comparison;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.labs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s20,
          vertical: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.near_me_outlined, size: 18, color: AppColors.accent),
            const SizedBox(width: AppSpacing.s8),
            Text(
              'Find Nearby Pharmacies',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pharmacy Availability Row ─────────────────────────────────────────────────

class _PharmacyAvailabilityRow extends StatelessWidget {
  const _PharmacyAvailabilityRow({required this.comparison});
  final MedicineComparison comparison;

  @override
  Widget build(BuildContext context) {
    final names = comparison.pharmacyNames;
    final count = comparison.pharmacyCount;
    if (count == 0) return const SizedBox.shrink();

    final shown = names.take(3).toList();
    final extra = count - shown.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_pharmacy_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available at $count ${count == 1 ? 'pharmacy' : 'pharmacies'}',
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  [...shown, if (extra > 0) '+$extra more'].join(' · '),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          GestureDetector(
            onTap: () => context.go(AppRoutes.labs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined, size: 14, color: AppColors.accent),
                const SizedBox(width: 3),
                Text(
                  'Map',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty Result ──────────────────────────────────────────────────────────────

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.search_off_rounded, size: 48, color: AppColors.border),
        const SizedBox(height: AppSpacing.s12),
        Text('No results for "$query"', style: AppTextStyles.labelLarge),
        const SizedBox(height: 4),
        Text(
          'Try searching by brand or generic name',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Scan Prompt Card ──────────────────────────────────────────────────────────

class _ScanPromptCard extends StatelessWidget {
  const _ScanPromptCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: AppShadows.md,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.r12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan Your Prescription',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get generic alternatives for all your medicines at once',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lab Scan Prompt Card ──────────────────────────────────────────────────────

class _LabScanPromptCard extends StatelessWidget {
  const _LabScanPromptCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s20),
        decoration: BoxDecoration(
          color: AppColors.successForeground,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: AppShadows.md,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.r12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: const Icon(
                Icons.biotech_outlined,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan Lab Test Prescription',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find the most affordable labs for your doctor\'s tests',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white60,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
