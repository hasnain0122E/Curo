import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/curo_button.dart';
import '../../../core/router/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _titles = [
    'Find Affordable Labs\nNear You',
    'Scan Your Prescription',
    'Understand Your Reports',
  ];

  static const _subtitles = [
    'Compare test prices across 100+ labs and book your slot in minutes.',
    'Point your camera at any prescription. AI reads the medicines and finds cheaper generics for you.',
    'AI explains every lab value in plain English or Urdu. Know exactly what your results mean.',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.signup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip row
            SizedBox(
              height: 52,
              child: _currentPage < 2
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.s20),
                        child: TextButton(
                          onPressed: () => context.go(AppRoutes.login),
                          child: Text(
                            'Skip',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _OnboardingPage(
                    illustration: const _LabsIllustration(),
                    title: _titles[0],
                    subtitle: _subtitles[0],
                  ),
                  _OnboardingPage(
                    illustration: const _PrescriptionIllustration(),
                    title: _titles[1],
                    subtitle: _subtitles[1],
                  ),
                  _OnboardingPage(
                    illustration: const _ReportsIllustration(),
                    title: _titles[2],
                    subtitle: _subtitles[2],
                  ),
                ],
              ),
            ),

            // Dots
            _DotsIndicator(currentPage: _currentPage, count: 3),
            const SizedBox(height: AppSpacing.s24),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
              child: Column(
                children: [
                  CuroButton(
                    label: _currentPage == 2 ? 'Get Started' : 'Next',
                    onPressed: _next,
                  ),
                  if (_currentPage == 2) ...[
                    const SizedBox(height: AppSpacing.s12),
                    CuroButton(
                      label: 'I Already Have an Account',
                      variant: CuroButtonVariant.text,
                      onPressed: () => context.go(AppRoutes.login),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.illustration,
    required this.title,
    required this.subtitle,
  });

  final Widget illustration;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s8),
              child: illustration,
            ),
          ),
          const SizedBox(height: AppSpacing.s32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.currentPage, required this.count});
  final int currentPage;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: active ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── Illustrations ─────────────────────────────────────────────────────────────

class _LabsIllustration extends StatelessWidget {
  const _LabsIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFDEEFFB),
        borderRadius: BorderRadius.circular(AppRadius.r24),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pakistan map background card
          Container(
            width: 220,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFF1E7FA0),
              borderRadius: BorderRadius.circular(AppRadius.r16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  color: Colors.white.withValues(alpha: 0.18),
                  size: 120,
                ),
                const Icon(Icons.location_on, color: Colors.white, size: 44),
              ],
            ),
          ),
          // Left floating card
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _FloatingIconCard(icon: Icons.science_outlined),
            ),
          ),
          // Right floating card
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _FloatingIconCard(icon: Icons.biotech_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionIllustration extends StatelessWidget {
  const _PrescriptionIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFDEEFFB),
        borderRadius: BorderRadius.circular(AppRadius.r24),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.r8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.s8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(width: 72, height: 8),
                    const SizedBox(height: 5),
                    _SkeletonLine(width: 52, height: 6),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            _MockRxField(),
            const SizedBox(height: AppSpacing.s4),
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(left: 4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            _MockRxField(),
          ],
        ),
      ),
    );
  }
}

class _MockRxField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Container(
            width: 52,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.r8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsIllustration extends StatelessWidget {
  const _ReportsIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFDEEFFB),
        borderRadius: BorderRadius.circular(AppRadius.r24),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 248,
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(width: 88, height: 8),
                    const SizedBox(height: 5),
                    _SkeletonLine(width: 60, height: 6),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Hemoglobin
            _LabMetricRow(
              label: 'Hemoglobin',
              value: '14.2 g/dL',
              valueColor: AppColors.success,
              progress: 0.64,
              barColor: AppColors.success,
            ),
            const SizedBox(height: 10),
            // Blood Sugar
            _LabMetricRow(
              label: 'Blood Sugar (PP)',
              value: '185 mg/dL',
              valueColor: AppColors.danger,
              progress: 0.78,
              barColor: AppColors.danger,
            ),
            const SizedBox(height: AppSpacing.s12),
            // AI hint row
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.r8),
                border: const Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.primary, size: 15),
                  const SizedBox(width: AppSpacing.s8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonLine(width: 90, height: 6),
                      const SizedBox(height: 5),
                      _SkeletonLine(width: 65, height: 6),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabMetricRow extends StatelessWidget {
  const _LabMetricRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.progress,
    required this.barColor,
  });

  final String label;
  final String value;
  final Color valueColor;
  final double progress;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}

class _FloatingIconCard extends StatelessWidget {
  const _FloatingIconCard({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.primary, size: 26),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
