import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/curo_bottom_nav_bar.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../providers/medipoints_provider.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.s16),
                    const _HomeHeader(),
                    const SizedBox(height: AppSpacing.s20),
                    const _HealthRiskCard(),
                    const SizedBox(height: AppSpacing.s20),
                    const _QuickActionsGrid(),
                    const SizedBox(height: AppSpacing.s24),
                  ],
                ),
              ),
              const _NearbyLabsSection(),
              const SizedBox(height: AppSpacing.s24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                child: const _CheapestLabSection(),
              ),
              const SizedBox(height: AppSpacing.s24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                child: const _RecentReportsSection(),
              ),
              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CuroBottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == 1) context.go(AppRoutes.labs);
          if (i == 2) context.go(AppRoutes.reports);
          if (i == 3) context.go(AppRoutes.medicines);
          if (i == 4) context.go(AppRoutes.profile);
        },
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(medipointsProvider);
    final profile = ref.watch(userProfileProvider);
    final firstName = profile.name.split(' ').first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Premium matte-teal avatar
        GestureDetector(
          onTap: () => context.go(AppRoutes.profile),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                profile.initials,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),

        // Greeting + MediPoints capsule
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_greeting()}, $firstName 👋', style: AppTextStyles.h3),
              const SizedBox(height: 5),
              _MedipointsCapsule(
                points: points,
                onTap: () => context.push(AppRoutes.medipoints),
              ),
            ],
          ),
        ),

        // Notification bell
        _NotificationBell(),
      ],
    );
  }
}

class _MedipointsCapsule extends StatelessWidget {
  const _MedipointsCapsule({required this.points, required this.onTap});
  final int points;
  final VoidCallback onTap;

  // Amber/gold tones — MediPoints brand identity
  static const _bg = Color(0xFFFEF3C7);
  static const _fg = Color(0xFFB45309);
  static const _sep = Color(0x3DB45309); // 24% alpha divider

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(AppRadius.r24),
          border: Border.all(color: _fg.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 12, color: _fg),
            const SizedBox(width: 4),
            Text(
              '$points pts',
              style: AppTextStyles.labelSmall.copyWith(
                color: _fg,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 7),
            Container(width: 1, height: 11, color: _sep),
            const SizedBox(width: 7),
            Text(
              'Details',
              style: AppTextStyles.labelSmall.copyWith(
                color: _fg,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.notifications),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
          Positioned(
            top: 9,
            right: 9,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.dangerForeground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Health Risk Card ──────────────────────────────────────────────────────────

class _HealthRiskCard extends ConsumerWidget {
  const _HealthRiskCard();

  static Color _riskBg(HealthRiskLevel level) => switch (level) {
    HealthRiskLevel.low => AppColors.successBackground,
    HealthRiskLevel.medium => AppColors.warningBackground,
    HealthRiskLevel.high => AppColors.dangerBackground,
  };

  static Color _riskFg(HealthRiskLevel level) => switch (level) {
    HealthRiskLevel.low => AppColors.successForeground,
    HealthRiskLevel.medium => AppColors.warningForeground,
    HealthRiskLevel.high => AppColors.dangerForeground,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final risk = ref.watch(healthRiskProvider);
    final bg = _riskBg(risk.level);
    final fg = _riskFg(risk.level);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primaryDark.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          // Circular gauge with status badge center
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s8),
            child: SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(84, 84),
                    painter: _GaugePainter(risk: risk, arcColor: fg),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      risk.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),

          // Title + explicit status badge + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Risk Score',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                // Distinct status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(AppRadius.r24),
                  ),
                  child: Text(
                    risk.label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Based on ${risk.reportCount} '
                  'report${risk.reportCount == 1 ? '' : 's'}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),

          // View Details CTA
          GestureDetector(
            onTap: () => context.go(AppRoutes.reports),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.r8),
              ),
              child: Text(
                'Details',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.risk, required this.arcColor});
  final HealthRiskData risk;
  final Color arcColor;

  static const double _startAngle = 5 * pi / 6;
  static const double _totalSweep = 4 * pi / 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawArc(
      rect,
      _startAngle,
      _totalSweep,
      false,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    // Fill
    canvas.drawArc(
      rect,
      _startAngle,
      _totalSweep * risk.gaugeProgress,
      false,
      Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.risk.level != risk.level || old.arcColor != arcColor;
}

// ── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  // Per-action color identities: Lab→accent, Report→success, Medicine→primary, LabTest→warning
  static const _actions = [
    (Icons.science_outlined, 'Find Lab', AppColors.accent),
    (
      Icons.document_scanner_outlined,
      'Scan Report',
      AppColors.successForeground,
    ),
    (Icons.medication_outlined, 'Find Medicine', AppColors.primary),
    (Icons.biotech_outlined, 'Scan Lab Test', AppColors.warningForeground),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: _actions[0].$1,
                label: _actions[0].$2,
                color: _actions[0].$3,
                onTap: () => context.go(AppRoutes.labs),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: _QuickActionCard(
                icon: _actions[1].$1,
                label: _actions[1].$2,
                color: _actions[1].$3,
                onTap: () => context.push(AppRoutes.reportUpload),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: _actions[2].$1,
                label: _actions[2].$2,
                color: _actions[2].$3,
                onTap: () => context.go(AppRoutes.medicines),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: _QuickActionCard(
                icon: _actions[3].$1,
                label: _actions[3].$2,
                color: _actions[3].$3,
                onTap: () => context.push(AppRoutes.labTestScanner),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nearby / Recently Visited Labs ────────────────────────────────────────────

class _NearbyLabsSection extends ConsumerWidget {
  const _NearbyLabsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labs = ref.watch(nearbyLabsProvider);
    final recentIds = ref.watch(recentlyViewedLabsProvider);
    final title = recentIds.isNotEmpty ? 'Recently Visited' : 'Nearby Labs';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.h3),
              GestureDetector(
                onTap: () => context.go(AppRoutes.labs),
                child: Text(
                  'See all',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        SizedBox(
          height: 186,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            itemCount: labs.length + 1,
            itemBuilder: (_, i) {
              if (i < labs.length) return _LabCard(lab: labs[i]);
              return _MoreLabsCard();
            },
          ),
        ),
      ],
    );
  }
}

class _LabCard extends StatelessWidget {
  const _LabCard({required this.lab});
  final NearbyLab lab;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.labs),
      child: Container(
        width: 156,
        margin: const EdgeInsets.only(right: AppSpacing.s12),
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lab avatar circle
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.biotech_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),

            // Lab name — high-contrast w700
            Text(
              lab.name,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Star rating
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: AppColors.ratingGold,
                ),
                const SizedBox(width: 3),
                Text(
                  lab.rating.toStringAsFixed(1),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),

            // Distance — clear separation, muted
            Row(
              children: [
                const Icon(
                  Icons.near_me_rounded,
                  size: 11,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 3),
                Text(
                  '${lab.distanceKm} km away',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
            const Spacer(),

            // Price — soft green pill tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.successBackground,
                borderRadius: BorderRadius.circular(AppRadius.r24),
              ),
              child: Text(
                'Rs. ${lab.fromPriceRs}+',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.successForeground,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreLabsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.labs),
      child: Container(
        width: 52,
        margin: const EdgeInsets.only(right: AppSpacing.s16),
        alignment: Alignment.center,
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ── Cheapest Lab ──────────────────────────────────────────────────────────────

class _CheapestLabSection extends ConsumerWidget {
  const _CheapestLabSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lab = ref.watch(cheapestLabProvider);
    if (lab == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Cheapest Nearby', style: AppTextStyles.h3),
            GestureDetector(
              onTap: () => context.go(AppRoutes.labs),
              child: Text(
                'See all',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        _CheapestLabCard(lab: lab),
      ],
    );
  }
}

class _CheapestLabCard extends StatelessWidget {
  const _CheapestLabCard({required this.lab});
  final NearbyLab lab;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.labs),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(
            color: AppColors.successForeground.withValues(alpha: 0.25),
          ),
          boxShadow: AppShadows.md,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.successBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.science_rounded,
                color: AppColors.successForeground,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lab.name,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: AppColors.ratingGold,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${lab.rating.toStringAsFixed(1)} · ${lab.distanceKm} km away',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successBackground,
                    borderRadius: BorderRadius.circular(AppRadius.r24),
                  ),
                  child: Text(
                    'BEST VALUE',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.successForeground,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'From Rs. ${lab.fromPriceRs}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.successForeground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent Reports ────────────────────────────────────────────────────────────

class _RecentReportsSection extends ConsumerWidget {
  const _RecentReportsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(recentReportsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Reports', style: AppTextStyles.h3),
            GestureDetector(
              onTap: () => context.go(AppRoutes.reports),
              child: Text(
                'View all',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.md,
          ),
          child: Column(
            children: [
              for (int i = 0; i < reports.length; i++) ...[
                _ReportRow(report: reports[i]),
                if (i < reports.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report});
  final RecentReport report;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.reports),
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: report.iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(report.icon, color: report.iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.name,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(report.date, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            StatusChip(label: report.statusLabel, variant: report.status),
            const SizedBox(width: AppSpacing.s8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
