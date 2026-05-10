import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/medipoints_provider.dart';
import '../../../providers/report_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../features/profile/providers/profile_provider.dart';

class MedipointsScreen extends ConsumerWidget {
  const MedipointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(medipointsProvider);
    final profile = ref.watch(userProfileProvider);
    final reportsAsync = ref.watch(userReportsProvider);
    final bookingsAsync = ref.watch(userBookingsProvider);
    final reportCount = reportsAsync.asData?.value.length ?? 0;
    final bookingCount = bookingsAsync.asData?.value.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Gradient App Bar / Hero ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF0B6B9E),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'MediPoints',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroBanner(points: points, name: profile.name),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── How to Earn ──────────────────────────────────────────────
                Text('How to Earn', style: AppTextStyles.h3),
                const SizedBox(height: AppSpacing.s12),
                _EarnCard(
                  icon: Icons.upload_file_rounded,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.primary.withValues(alpha: 0.10),
                  title: 'Upload a Lab Report',
                  subtitle: 'Scan or upload any medical report',
                  pts: '+50 pts',
                ),
                const SizedBox(height: AppSpacing.s8),
                _EarnCard(
                  icon: Icons.science_rounded,
                  iconColor: AppColors.success,
                  iconBg: AppColors.success.withValues(alpha: 0.10),
                  title: 'Book a Lab Test',
                  subtitle: 'Book any test through CURO',
                  pts: '+30 pts',
                ),
                const SizedBox(height: AppSpacing.s8),
                _EarnCard(
                  icon: Icons.person_add_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  iconBg: const Color(0xFF8B5CF6).withValues(alpha: 0.10),
                  title: 'Refer a Friend',
                  subtitle: 'Invite friends to join CURO',
                  pts: '+100 pts',
                  comingSoon: true,
                ),

                const SizedBox(height: AppSpacing.s24),

                // ── Benefits ─────────────────────────────────────────────────
                Text('Your Benefits', style: AppTextStyles.h3),
                const SizedBox(height: AppSpacing.s12),
                _BenefitCard(
                  icon: Icons.local_offer_rounded,
                  title: 'Rs 50 off any lab booking',
                  subtitle: 'Redeem 100 MediPoints',
                  unlocked: points >= 100,
                ),
                const SizedBox(height: AppSpacing.s8),
                _BenefitCard(
                  icon: Icons.discount_rounded,
                  title: '10% off lab tests',
                  subtitle: 'Redeem 300 MediPoints',
                  unlocked: points >= 300,
                ),
                const SizedBox(height: AppSpacing.s8),
                _BenefitCard(
                  icon: Icons.support_agent_rounded,
                  title: 'Priority Support',
                  subtitle: 'Redeem 500 MediPoints',
                  unlocked: points >= 500,
                ),

                const SizedBox(height: AppSpacing.s24),

                // ── Activity ─────────────────────────────────────────────────
                Text('Recent Activity', style: AppTextStyles.h3),
                const SizedBox(height: AppSpacing.s12),

                if (reportCount == 0 && bookingCount == 0)
                  _EmptyActivity()
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < reportCount; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: AppColors.border),
                          _ActivityRow(
                            icon: Icons.upload_file_rounded,
                            label: 'Report Uploaded',
                            pts: '+50 pts',
                            color: AppColors.primary,
                          ),
                        ],
                        for (int i = 0; i < bookingCount; i++) ...[
                          if (i > 0 || reportCount > 0)
                            const Divider(height: 1, color: AppColors.border),
                          _ActivityRow(
                            icon: Icons.science_rounded,
                            label: 'Lab Test Booked',
                            pts: '+30 pts',
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.s24),

                // ── Info note ────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Text(
                          'MediPoints are earned automatically when you upload reports '
                          'or book tests through CURO. Points never expire.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.s32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Banner ───────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.points, required this.name});
  final int points;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B4F72), Color(0xFF1184B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.s20, 56, AppSpacing.s20, AppSpacing.s24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Balance',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$points',
                          style: AppTextStyles.h1.copyWith(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'pts',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      points == 0
                          ? 'Upload a report to earn your first points!'
                          : 'Keep earning to unlock rewards',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded,
                    color: Color(0xFFFCD34D), size: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Earn Card ─────────────────────────────────────────────────────────────────

class _EarnCard extends StatelessWidget {
  const _EarnCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.pts,
    this.comingSoon = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String pts;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: comingSoon
            ? AppColors.surface.withValues(alpha: 0.6)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: comingSoon
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    )),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          if (comingSoon)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.r4),
              ),
              child: Text(
                'Soon',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textSecondary, fontSize: 10),
              ),
            )
          else
            Text(
              pts,
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.success),
            ),
        ],
      ),
    );
  }
}

// ── Benefit Card ──────────────────────────────────────────────────────────────

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.unlocked,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(
          color: unlocked
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.success.withValues(alpha: 0.10)
                  : AppColors.border.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: unlocked ? AppColors.success : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: unlocked
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    )),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Icon(
            unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
            size: 18,
            color: unlocked ? AppColors.success : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ── Activity Row ──────────────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.label,
    required this.pts,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String pts;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(label, style: AppTextStyles.labelMedium),
          ),
          Text(pts,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.success)),
        ],
      ),
    );
  }
}

// ── Empty Activity ────────────────────────────────────────────────────────────

class _EmptyActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.star_outline_rounded,
              size: 40, color: AppColors.border),
          const SizedBox(height: AppSpacing.s12),
          Text('No activity yet', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Upload a report or book a lab test\nto start earning MediPoints.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
