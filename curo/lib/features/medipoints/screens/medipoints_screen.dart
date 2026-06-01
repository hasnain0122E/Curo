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
          // ── Wallet Passport Hero ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 252,
            pinned: true,
            backgroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.white,
              ),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'MediPoints',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _WalletHero(points: points, name: profile.name),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── How to Earn — Timeline ────────────────────────────────
                Text('How to Earn', style: AppTextStyles.h3),
                const SizedBox(height: AppSpacing.s16),
                _EarnTimelineItem(
                  icon: Icons.upload_file_rounded,
                  iconColor: AppColors.accent,
                  iconBg: AppColors.accent.withValues(alpha: 0.10),
                  title: 'Upload a Lab Report',
                  subtitle: 'Scan or upload any medical report',
                  pts: '+50 pts',
                  isLast: false,
                ),
                _EarnTimelineItem(
                  icon: Icons.science_rounded,
                  iconColor: AppColors.successForeground,
                  iconBg: AppColors.successBackground,
                  title: 'Book a Lab Test',
                  subtitle: 'Book any test through CURO',
                  pts: '+30 pts',
                  isLast: false,
                ),
                _EarnTimelineItem(
                  icon: Icons.person_add_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  iconBg: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                  title: 'Refer a Friend',
                  subtitle: 'Invite friends to join CURO',
                  pts: '+100 pts',
                  isLast: true,
                  comingSoon: true,
                ),

                const SizedBox(height: AppSpacing.s24),

                // ── Benefits ──────────────────────────────────────────────
                Text('Your Benefits', style: AppTextStyles.h3),
                const SizedBox(height: AppSpacing.s12),
                _BenefitRow(
                  icon: Icons.local_offer_rounded,
                  title: 'Rs 50 off any lab booking',
                  subtitle: 'Requires 100 MediPoints',
                  unlocked: points >= 100,
                ),
                const SizedBox(height: AppSpacing.s8),
                _BenefitRow(
                  icon: Icons.discount_rounded,
                  title: '10% off lab tests',
                  subtitle: 'Requires 300 MediPoints',
                  unlocked: points >= 300,
                ),
                const SizedBox(height: AppSpacing.s8),
                _BenefitRow(
                  icon: Icons.support_agent_rounded,
                  title: 'Priority Support',
                  subtitle: 'Requires 500 MediPoints',
                  unlocked: points >= 500,
                ),

                const SizedBox(height: AppSpacing.s24),

                // ── Recent Activity ───────────────────────────────────────
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
                      boxShadow: AppShadows.md,
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
                            color: AppColors.accent,
                          ),
                        ],
                        for (int i = 0; i < bookingCount; i++) ...[
                          if (i > 0 || reportCount > 0)
                            const Divider(height: 1, color: AppColors.border),
                          _ActivityRow(
                            icon: Icons.science_rounded,
                            label: 'Lab Test Booked',
                            pts: '+30 pts',
                            color: AppColors.successForeground,
                          ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.s24),

                // ── Info note ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
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

// ── Wallet Hero ───────────────────────────────────────────────────────────────

class _WalletHero extends StatelessWidget {
  const _WalletHero({required this.points, required this.name});
  final int points;
  final String name;

  String get _tier {
    if (points >= 500) return 'Gold Member';
    if (points >= 200) return 'Silver Member';
    return 'Member';
  }

  Color get _tierAccent {
    if (points >= 500) return const Color(0xFFFCD34D);
    if (points >= 200) return const Color(0xFFCBD5E1);
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: Stack(
        children: [
          // ── Decorative depth circles ───────────────────────────────────
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 24,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -16,
            left: -24,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20,
                56,
                AppSpacing.s20,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Balance label + points + star seal
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR BALANCE',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.50),
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$points',
                                  style: AppTextStyles.h1.copyWith(
                                    color: Colors.white,
                                    fontSize: 52,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.5,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'pts',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.58,
                                      ),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Star seal
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFCD34D),
                          size: 28,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Muted tracking chip — distinct background
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(AppRadius.r24),
                    ),
                    child: Text(
                      points == 0
                          ? 'Upload a report to earn your first points!'
                          : 'Keep earning to unlock rewards',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 11,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Electric-blue accent divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.55),
                          AppColors.accent.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Holder name + tier badge row
                  Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 13,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        name,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.80),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadius.r24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          _tier,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _tierAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Earn Timeline Item ────────────────────────────────────────────────────────

class _EarnTimelineItem extends StatelessWidget {
  const _EarnTimelineItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.pts,
    required this.isLast,
    this.comingSoon = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String pts;
  final bool isLast;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline spine ─────────────────────────────────────────────
          Column(
            children: [
              // Icon node
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: comingSoon
                      ? AppColors.border.withValues(alpha: 0.6)
                      : iconBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: comingSoon
                        ? AppColors.border
                        : iconColor.withValues(alpha: 0.28),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: comingSoon ? AppColors.textSecondary : iconColor,
                ),
              ),
              // Connector line (not shown on last item)
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: AppSpacing.s16),

          // ── Content ────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 8,
                bottom: isLast ? 0 : AppSpacing.s24,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: comingSoon
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(subtitle, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  // Pts pill — tinted to match action color
                  if (comingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.border.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppRadius.r24),
                      ),
                      child: Text(
                        'Soon',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(AppRadius.r24),
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        pts,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: iconColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Benefit Row ───────────────────────────────────────────────────────────────

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(
          color: unlocked
              ? AppColors.accent.withValues(alpha: 0.28)
              : AppColors.border,
        ),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.accent.withValues(alpha: 0.08)
                  : AppColors.border.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: unlocked ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: unlocked
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.s12),

          // Redeem text action — no button box, clean color weight
          Text(
            'Redeem',
            style: AppTextStyles.labelMedium.copyWith(
              color: unlocked ? AppColors.accent : AppColors.textSecondary,
              fontWeight: unlocked ? FontWeight.w600 : FontWeight.w400,
            ),
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
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
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
          Expanded(child: Text(label, style: AppTextStyles.labelMedium)),
          // Pts pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.r24),
            ),
            child: Text(
              pts,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
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
        boxShadow: AppShadows.md,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.star_outline_rounded,
            size: 40,
            color: AppColors.border,
          ),
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
