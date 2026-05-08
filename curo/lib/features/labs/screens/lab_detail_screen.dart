import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/curo_button.dart';
import '../models/lab_booking_models.dart';
import '../providers/lab_booking_provider.dart';
import '../providers/lab_map_provider.dart';

class LabDetailScreen extends ConsumerWidget {
  const LabDetailScreen({super.key, required this.lab});

  final LabLocation lab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tests = ref.watch(labTestsProvider(lab.id));
    final hours = ref.watch(labOpeningHoursProvider(lab.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero
          SliverToBoxAdapter(child: _HeroSection(lab: lab, hours: hours)),

          // Section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s20, AppSpacing.s16, AppSpacing.s12),
              child: Row(
                children: [
                  Text('Available Tests', style: AppTextStyles.h3),
                  const SizedBox(width: AppSpacing.s8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.r24),
                    ),
                    child: Text(
                      '${tests.length}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Test cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _TestCard(test: tests[i], lab: lab),
                childCount: tests.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s32)),
        ],
      ),
    );
  }
}

// ── Hero Section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.lab, required this.hours});

  final LabLocation lab;
  final String hours;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF36BDF2), Color(0xFF0D7AB5)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s20),

              // Lab avatar + name + address + rating
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.science_rounded,
                      color: lab.avatarColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lab.name,
                          style: AppTextStyles.h2.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                color: Colors.white.withValues(alpha: 0.75), size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lab.address,
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withValues(alpha: 0.75)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFD700), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${lab.rating}  ·  ${lab.reviewCount} reviews',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s20),

              // Info chips
              Wrap(
                spacing: AppSpacing.s8,
                children: [
                  _InfoChip(
                      icon: Icons.near_me_rounded,
                      label: '${lab.distanceKm} km'),
                  _InfoChip(icon: Icons.access_time_rounded, label: hours),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.r24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ── Test Card ─────────────────────────────────────────────────────────────────

class _TestCard extends StatelessWidget {
  const _TestCard({required this.test, required this.lab});

  final LabTest test;
  final LabLocation lab;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Icon(test.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(test.name, style: AppTextStyles.labelLarge),
                const SizedBox(height: 3),
                Text(
                  '${test.category}  ·  ~${test.turnaroundHours}h result',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₨ ${test.priceRs}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              CuroButton(
                label: 'Book',
                width: 72,
                onPressed: () => context.push(
                  AppRoutes.labBooking,
                  extra: {'lab': lab, 'test': test},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
