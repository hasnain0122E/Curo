import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/curo_bottom_nav_bar.dart';
import '../../../core/widgets/curo_button.dart';
import '../../../core/router/app_router.dart';
import '../models/medicine_models.dart';
import '../providers/medicine_provider.dart';

class MedicineFinderScreen extends ConsumerStatefulWidget {
  const MedicineFinderScreen({super.key});

  @override
  ConsumerState<MedicineFinderScreen> createState() =>
      _MedicineFinderScreenState();
}

class _MedicineFinderScreenState
    extends ConsumerState<MedicineFinderScreen> {
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text('Medicine Finder', style: AppTextStyles.h3),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.medicineScanner),
            icon: const Icon(Icons.document_scanner_rounded,
                color: AppColors.primary, size: 22),
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
                const Icon(Icons.search_rounded,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: notifier.searchMedicine,
                    textInputAction: TextInputAction.search,
                    onSubmitted: notifier.searchMedicine,
                    decoration: InputDecoration(
                      hintText: 'Search branded or generic medicine...',
                      hintStyle: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
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
                      child: Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textSecondary),
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
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.s8),
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
                        horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
                    decoration: BoxDecoration(
                      color:
                          isActive ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.r24),
                      border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color:
                            isActive ? Colors.white : AppColors.textPrimary,
                      ),
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
            _BrandedCard(comparison: state.comparison!),
            const SizedBox(height: AppSpacing.s4),
            _VsSeparator(),
            const SizedBox(height: AppSpacing.s4),
            _GenericCard(comparison: state.comparison!),
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
          ],

          const SizedBox(height: AppSpacing.s16),
        ],
      ),
      bottomNavigationBar: CuroBottomNavBar(
        currentIndex: 3,
        onTap: _onNavTap,
      ),
    );
  }
}

// ── Branded Card ──────────────────────────────────────────────────────────────

class _BrandedCard extends StatelessWidget {
  const _BrandedCard({required this.comparison});
  final MedicineComparison comparison;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Red X icon
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_outlined,
                color: AppColors.danger, size: 20),
          ),
          const SizedBox(width: AppSpacing.s12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(comparison.brandedName,
                          style: AppTextStyles.h3),
                    ),
                    if (comparison.prescriptionRequired) ...[
                      const SizedBox(width: 6),
                      _Pill(label: 'Rx', color: const Color(0xFF7C3AED),
                          bgColor: const Color(0xFFF5F3FF)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(comparison.brandedMaker,
                    style: AppTextStyles.bodySmall),
                if (comparison.brandedForm.isNotEmpty)
                  Text(comparison.brandedForm,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary)),
              ],
            ),
          ),

          // Pill + price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Pill(label: 'FULL PRICE', color: AppColors.textSecondary),
              const SizedBox(height: 6),
              Text(
                'Rs ${comparison.brandedPriceRs}',
                style: AppTextStyles.h2.copyWith(color: AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── VS Separator ──────────────────────────────────────────────────────────────

class _VsSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        const SizedBox(width: AppSpacing.s8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r24),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14, color: AppColors.textSecondary),
              Text(' VS ', style: AppTextStyles.labelSmall),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14, color: AppColors.textSecondary),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

// ── Generic Card ──────────────────────────────────────────────────────────────

class _GenericCard extends StatelessWidget {
  const _GenericCard({required this.comparison});
  final MedicineComparison comparison;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(
            color: AppColors.success.withValues(alpha: 0.40), width: 1.5),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Green check icon
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.success, size: 20),
              ),
              const SizedBox(width: AppSpacing.s12),

              // Name + pills
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: 4,
                      children: [
                        if (comparison.savingsPercent > 0)
                          _Pill(
                            label: 'SAVE ${comparison.savingsPercent}%',
                            color: AppColors.success,
                            bgColor: const Color(0xFFF0FDF4),
                          )
                        else
                          _Pill(
                              label: 'GENERIC',
                              color: AppColors.success,
                              bgColor: const Color(0xFFF0FDF4)),
                        _Pill(
                          label: comparison.category.toUpperCase(),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(comparison.genericName, style: AppTextStyles.h3),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),

          // Description
          Text(
            comparison.genericDesc,
            style: AppTextStyles.bodySmall.copyWith(height: 1.6),
          ),

          // Usage instruction
          if (comparison.firstUsage.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    comparison.firstUsage,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.s12),

          // Price row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rs ${comparison.genericPriceRs}',
                style: AppTextStyles.h2.copyWith(color: AppColors.success),
              ),
              if (comparison.priceDiffPercent > 0)
                Text(
                  '${comparison.priceDiffPercent}% less than branded',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                    fontSize: 10,
                  ),
                ),
            ],
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
    return CuroButton(
      label: 'Find Nearby Pharmacies',
      icon: Icons.local_pharmacy_rounded,
      onPressed: () => context.go(AppRoutes.labs),
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
          const Icon(Icons.local_pharmacy_rounded,
              size: 18, color: AppColors.primary),
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
                  [
                    ...shown,
                    if (extra > 0) '+$extra more',
                  ].join(' · '),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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
        const Icon(Icons.search_off_rounded,
            size: 48, color: AppColors.border),
        const SizedBox(height: AppSpacing.s12),
        Text(
          'No results for "$query"',
          style: AppTextStyles.labelLarge,
        ),
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
          gradient: const LinearGradient(
            colors: [Color(0xFF0F4C6B), Color(0xFF1A6A94)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: const Icon(Icons.document_scanner_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scan Your Prescription',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    'Get generic alternatives for all your medicines at once',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white60, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Pill badge ────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    this.bgColor = const Color(0xFFF1F5F9),
  });

  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.r4),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
