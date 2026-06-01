import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/curo_button.dart';
import '../../../core/router/app_router.dart';
import '../providers/lab_test_scan_provider.dart';
import '../providers/lab_map_provider.dart';

// ── Hardcoded lab demo data ───────────────────────────────────────────────────

class _MockLab {
  const _MockLab({
    required this.name,
    required this.area,
    required this.distanceKm,
    required this.testPrices,
  });

  final String name;
  final String area;
  final String distanceKm;
  final Map<String, int> testPrices;

  int get totalRs => testPrices.values.fold(0, (a, b) => a + b);
}

final _mockLabs = [
  _MockLab(
    name: 'Olatech Labs',
    area: 'North Karachi',
    distanceKm: '1.2 km',
    testPrices: {
      'CBC': 250,
      'LFT': 500,
      'Blood Sugar Fasting': 150,
      'Urine DR': 140,
    },
  ),
  _MockLab(
    name: 'Essa Lab',
    area: 'Nazimabad, Karachi',
    distanceKm: '2.8 km',
    testPrices: {
      'CBC': 280,
      'LFT': 550,
      'Blood Sugar Fasting': 180,
      'Urine DR': 160,
    },
  ),
  _MockLab(
    name: 'Excel Lab',
    area: 'DHA Phase 6, Karachi',
    distanceKm: '4.3 km',
    testPrices: {
      'CBC': 300,
      'LFT': 600,
      'Blood Sugar Fasting': 200,
      'Urine DR': 180,
    },
  ),
  _MockLab(
    name: 'Chughtai Lab',
    area: 'Gulshan-e-Iqbal, Karachi',
    distanceKm: '5.1 km',
    testPrices: {
      'CBC': 350,
      'LFT': 650,
      'Blood Sugar Fasting': 250,
      'Urine DR': 200,
    },
  ),
];

class LabTestScanResultScreen extends ConsumerWidget {
  const LabTestScanResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tests = ref.watch(labTestScanProvider);

    void findAffordableLabs() {
      ref.read(labTestNamesFilterProvider.notifier).set(tests);
      ref.read(labFilterProvider.notifier).set(LabFilter.cheapest);
      context.go(AppRoutes.labs);
    }

    void browseAllLabs() {
      ref.read(labTestNamesFilterProvider.notifier).set([]);
      ref.read(labFilterProvider.notifier).set(LabFilter.cheapest);
      context.go(AppRoutes.labs);
    }

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
        title: Text('Lab Tests Found', style: AppTextStyles.h3),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: tests.isEmpty
          ? _buildEmptyState(context, browseAllLabs)
          : _buildResults(context, ref, tests, findAffordableLabs),
    );
  }

  Widget _buildResults(
    BuildContext context,
    WidgetRef ref,
    List<String> tests,
    VoidCallback onFind,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        // Success banner
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(AppRadius.r12),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                '${tests.length} lab test${tests.length == 1 ? '' : 's'} detected',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.s16),

        // Test list
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < tests.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                _TestRow(
                  name: tests[i],
                  onRemove: () =>
                      ref.read(labTestScanProvider.notifier).removeTest(i),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.s24),

        // Affordable labs section
        Row(
          children: [
            Text('Affordable Labs Nearby', style: AppTextStyles.labelLarge),
            const SizedBox(width: AppSpacing.s8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.r24),
              ),
              child: Text(
                'Lowest first',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.s12),

        for (final lab in _mockLabs) ...[
          _LabCostCard(lab: lab, tests: tests, onTap: onFind),
          const SizedBox(height: AppSpacing.s8),
        ],

        const SizedBox(height: AppSpacing.s16),

        CuroButton(
          label: 'Browse All Labs on Map',
          icon: Icons.map_rounded,
          onPressed: onFind,
        ),

        const SizedBox(height: AppSpacing.s16),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, VoidCallback onBrowse) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.s48),
          const Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppColors.border,
          ),
          const SizedBox(height: AppSpacing.s16),
          Text('No lab tests detected', style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Try taking a clearer photo of the prescription,\nor browse all labs directly.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s32),
          CuroButton(
            label: 'Browse Affordable Labs',
            icon: Icons.science_rounded,
            onPressed: onBrowse,
          ),
        ],
      ),
    );
  }
}

// ── Lab Cost Card ─────────────────────────────────────────────────────────────

class _LabCostCard extends StatelessWidget {
  const _LabCostCard({
    required this.lab,
    required this.tests,
    required this.onTap,
  });

  final _MockLab lab;
  final List<String> tests;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final relevantPrices = {
      for (final t in tests)
        if (lab.testPrices.containsKey(t)) t: lab.testPrices[t]!,
    };
    final total = relevantPrices.values.fold(0, (a, b) => a + b);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lab.name, style: AppTextStyles.labelLarge),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            lab.area,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Text(
                            '· ${lab.distanceKm}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs $total',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      'total',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),

            if (relevantPrices.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.s8),
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s4,
                children: relevantPrices.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.r4),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${e.key}  Rs ${e.value}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Test Row ──────────────────────────────────────────────────────────────────

class _TestRow extends StatelessWidget {
  const _TestRow({required this.name, required this.onRemove});
  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.biotech_outlined,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(child: Text(name, style: AppTextStyles.labelLarge)),
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.only(left: AppSpacing.s8),
              child: Icon(
                Icons.close_rounded,
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
