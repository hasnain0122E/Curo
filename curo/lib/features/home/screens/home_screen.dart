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
              // Header + risk card + quick actions — padded section
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

              // Nearby Labs — edge-to-edge with its own horizontal padding
              const _NearbyLabsSection(),
              const SizedBox(height: AppSpacing.s24),

              // Cheapest Lab — full-width card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                child: const _CheapestLabSection(),
              ),
              const SizedBox(height: AppSpacing.s24),

              // Recent Reports — padded
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
        // Avatar
        GestureDetector(
          onTap: () => context.go(AppRoutes.profile),
          child: Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                profile.initials,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),

        // Greeting + MediPoints
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_greeting()}, $firstName 👋', style: AppTextStyles.h3),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => context.push(AppRoutes.medipoints),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MedipointsBadge(points: points),
                    const SizedBox(width: 4),
                    Text(
                      'View details',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFFD97706),
                        fontSize: 10,
                        decoration: TextDecoration.underline,
                        decorationColor: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
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

class _MedipointsBadge extends StatelessWidget {
  const _MedipointsBadge({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(AppRadius.r24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFD97706)),
          const SizedBox(width: 4),
          Text(
            '${points}pts',
            style: AppTextStyles.labelSmall.copyWith(
              color: const Color(0xFFD97706),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
                color: AppColors.danger,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final risk = ref.watch(healthRiskProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          // Circular gauge
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(84, 84),
                  painter: _GaugePainter(risk: risk),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      risk.label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: risk.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s16),

          // Title + subtitle
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
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${risk.label} ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: risk.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: 'Based on ${risk.reportCount}\nreports',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // View Details
          GestureDetector(
            onTap: () => context.go(AppRoutes.reports),
            child: Text(
              'View\nDetails',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.risk});
  final HealthRiskData risk;

  // Arc: starts at ~8 o'clock, sweeps 240° clockwise through top to ~4 o'clock
  static const double _startAngle = 5 * pi / 6; // 150° from 3-o'clock = 8 o'clock area
  static const double _totalSweep = 4 * pi / 3; // 240°

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
        ..color = risk.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.risk.level != risk.level;
}

// ── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const _actions = [
    (Icons.science_outlined, 'Find Lab'),
    (Icons.document_scanner_outlined, 'Scan Report'),
    (Icons.medication_outlined, 'Find Medicine'),
    (Icons.biotech_outlined, 'Scan Lab Test'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _QuickActionCard(
              icon: _actions[0].$1, label: _actions[0].$2,
              onTap: () => context.go(AppRoutes.labs),
            )),
            const SizedBox(width: AppSpacing.s12),
            Expanded(child: _QuickActionCard(
              icon: _actions[1].$1, label: _actions[1].$2,
              onTap: () => context.push(AppRoutes.reportUpload),
            )),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            Expanded(child: _QuickActionCard(
              icon: _actions[2].$1, label: _actions[2].$2,
              onTap: () => context.go(AppRoutes.medicines),
            )),
            const SizedBox(width: AppSpacing.s12),
            Expanded(child: _QuickActionCard(
              icon: _actions[3].$1, label: _actions[3].$2,
              onTap: () => context.push(AppRoutes.labTestScanner),
            )),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              label,
              style: AppTextStyles.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nearby Labs ───────────────────────────────────────────────────────────────

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
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        SizedBox(
          height: 178,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            itemCount: labs.length + 1,
            itemBuilder: (_, i) {
              if (i < labs.length) {
                return _LabCard(lab: labs[i]);
              }
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
      width: 152,
      margin: const EdgeInsets.only(right: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: lab.avatarColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.science_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(height: AppSpacing.s8),

          // Name
          Text(
            lab.name,
            style: AppTextStyles.labelLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Rating row
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
              const SizedBox(width: 3),
              Text(
                lab.rating.toStringAsFixed(1),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
              ),
              Text(
                ' · ${lab.distanceKm}km',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Price
          Text(
            'From Rs. ${lab.fromPriceRs}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),   // closes Container
  );     // closes GestureDetector
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
            color: AppColors.primary,
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
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
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
          border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.science_rounded,
                  color: AppColors.success, size: 24),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lab.name,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 12, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        '${lab.rating.toStringAsFixed(1)} · ${lab.distanceKm}km away',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(AppRadius.r4),
                  ),
                  child: Text(
                    'BEST VALUE',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'From Rs. ${lab.fromPriceRs}',
                  style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.success),
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
                  color: AppColors.primary,
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
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: [
              for (int i = 0; i < reports.length; i++) ...[
                _ReportRow(report: reports[i]),
                if (i < reports.length - 1)
                  const Divider(height: 1, thickness: 1, color: AppColors.border),
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
      child: Padding(
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Row(
        children: [
          // Icon circle
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

          // Name + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.name, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(report.date, style: AppTextStyles.bodySmall),
              ],
            ),
          ),

          // Status chip
          StatusChip(label: report.statusLabel, variant: report.status),
          const SizedBox(width: AppSpacing.s8),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    ),   // closes Padding
  );     // closes InkWell
  }
}
