import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/curo_button.dart';
import '../../../core/widgets/curo_bottom_nav_bar.dart';
import '../models/report_models.dart';
import '../providers/report_provider.dart';

class ReportUploadScreen extends ConsumerWidget {
  const ReportUploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(reportProvider.select((s) => s.phase));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _ReportAppBar(phase: phase),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: switch (phase) {
          ReportScreenPhase.upload => const _UploadView(key: ValueKey('upload')),
          ReportScreenPhase.processing =>
            const _ProcessingView(key: ValueKey('processing')),
          ReportScreenPhase.results =>
            const _ResultsView(key: ValueKey('results')),
          ReportScreenPhase.error => const _ErrorView(key: ValueKey('error')),
        },
      ),
      bottomNavigationBar: phase == ReportScreenPhase.results
          ? null
          : CuroBottomNavBar(
              currentIndex: 2,
              onTap: (i) {
                if (i == 0) context.go(AppRoutes.home);
                if (i == 1) context.go(AppRoutes.labs);
                if (i == 2) context.go(AppRoutes.reports);
                if (i == 3) context.go(AppRoutes.medicines);
                if (i == 4) context.go(AppRoutes.profile);
              },
            ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _ReportAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ReportAppBar({required this.phase});
  final ReportScreenPhase phase;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isResults = phase == ReportScreenPhase.results;
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        isResults ? 'Report Results' : 'AI Report Analysis',
        style: AppTextStyles.h3,
      ),
      leading: isResults
          ? Consumer(
              builder: (_, ref, _) => IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.textPrimary),
                onPressed: () => ref.read(reportProvider.notifier).reset(),
              ),
            )
          : null,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
    );
  }
}

// ── STATE 1: Upload ───────────────────────────────────────────────────────────

class _UploadView extends ConsumerWidget {
  const _UploadView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportProvider);
    final notifier = ref.read(reportProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.s8),
          Text('Upload Lab Report', style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text(
            'Upload your lab report for instant AI analysis',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s24),

          // Drop zone
          GestureDetector(
            onTap: notifier.pickFile,
            child: CustomPaint(
              painter: _DashedBorderPainter(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 36, horizontal: AppSpacing.s16),
                decoration: BoxDecoration(
                  color: state.hasFile
                      ? AppColors.primary.withValues(alpha: 0.04)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                ),
                child: state.hasFile
                    ? _FilePreview(fileName: state.fileName!)
                    : const _DropZonePrompt(),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.s16),

          // Camera option
          GestureDetector(
            onTap: notifier.takePhoto,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.r12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF8FE),
                      borderRadius: BorderRadius.circular(AppRadius.r8),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Take a Photo', style: AppTextStyles.labelLarge),
                        Text(
                          'Capture your report with camera',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.s16),

          // Format info pills
          Text('Supported formats', style: AppTextStyles.labelMedium),
          const SizedBox(height: AppSpacing.s8),
          const Wrap(
            spacing: AppSpacing.s8,
            children: [
              _FormatPill('PDF'),
              _FormatPill('JPG'),
              _FormatPill('PNG'),
            ],
          ),

          const SizedBox(height: AppSpacing.s24),

          // Info cards
          const _InfoCard(
            icon: Icons.security_rounded,
            title: 'Your data is private',
            body: 'Reports are processed securely and never stored.',
          ),
          const SizedBox(height: AppSpacing.s12),
          const _InfoCard(
            icon: Icons.info_outline_rounded,
            title: 'AI assistance only',
            body: 'Results are informational. Always consult your doctor.',
          ),

          const SizedBox(height: AppSpacing.s32),

          CuroButton(
            label: 'Analyze Report',
            onPressed: state.hasFile
                ? () => ref.read(reportProvider.notifier).analyzeReport()
                : null,
            icon: Icons.auto_awesome_rounded,
          ),

          const SizedBox(height: AppSpacing.s16),
        ],
      ),
    );
  }
}

class _DropZonePrompt extends StatelessWidget {
  const _DropZonePrompt();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF8FE),
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          child: const Icon(Icons.upload_file_rounded,
              color: AppColors.primary, size: 32),
        ),
        const SizedBox(height: AppSpacing.s16),
        Text('Tap to upload report', style: AppTextStyles.labelLarge),
        const SizedBox(height: 4),
        Text(
          'or drag and drop here',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _FilePreview extends StatelessWidget {
  const _FilePreview({required this.fileName});
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF8FE),
            borderRadius: BorderRadius.circular(AppRadius.r8),
          ),
          child: const Icon(Icons.description_rounded,
              color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: AppTextStyles.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text('Ready for analysis', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded,
            color: AppColors.success, size: 20),
      ],
    );
  }
}

class _FormatPill extends StatelessWidget {
  const _FormatPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r24),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: AppTextStyles.labelMedium),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMedium),
                const SizedBox(height: 2),
                Text(body, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── STATE 2: Processing ───────────────────────────────────────────────────────

class _ProcessingView extends ConsumerStatefulWidget {
  const _ProcessingView({super.key});

  @override
  ConsumerState<_ProcessingView> createState() => _ProcessingViewState();
}

class _ProcessingViewState extends ConsumerState<_ProcessingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  static const _steps = [
    (Icons.cloud_upload_rounded, 'Uploading report...'),
    (Icons.document_scanner_rounded, 'Reading values...'),
    (Icons.auto_awesome_rounded, 'AI is analyzing...'),
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(reportProvider.select((s) => s.processingStep));

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF8FE),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.20),
                      blurRadius: 32,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primary, size: 44),
              ),
            ),
            const SizedBox(height: AppSpacing.s32),
            Text('Analyzing Report', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Our AI is reading your lab values\nand generating insights.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s48),
            ..._steps.asMap().entries.map((e) {
              final i = e.key;
              final (icon, label) = e.value;
              final done = step > i;
              final active = step == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: done
                            ? AppColors.success
                            : active
                                ? AppColors.primary
                                : AppColors.border,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        done ? Icons.check_rounded : icon,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: done || active
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(width: AppSpacing.s8),
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── STATE 3: Results ──────────────────────────────────────────────────────────

class _ResultsView extends ConsumerWidget {
  const _ResultsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportProvider);
    final summary = state.summary!;
    final meta = state.meta!;
    final results = state.results;

    return CustomScrollView(
      slivers: [
        // Patient meta header
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16, vertical: AppSpacing.s16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEBF8FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meta.patientName, style: AppTextStyles.labelLarge),
                      Text(
                        '${meta.labName}  •  ${meta.date}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF8FE),
                    borderRadius: BorderRadius.circular(AppRadius.r24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('AI Analysed',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(
            child: Divider(height: 1, color: AppColors.border)),

        // AI Summary card (dark teal)
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.s16),
            padding: const EdgeInsets.all(AppSpacing.s20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F4C6B), Color(0xFF1A6A94)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.r16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      'AI Summary',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(
                  summary.headline,
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  summary.body,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: AppSpacing.s16),
                Row(
                  children: [
                    _SummaryChip(
                      label: '${summary.testsAnalyzed} Tests',
                      icon: Icons.science_rounded,
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    _SummaryChip(
                      label: '${summary.criticalAlerts} Alerts',
                      icon: Icons.warning_amber_rounded,
                      highlight: summary.criticalAlerts > 0,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s8),
            child: Text('Test Results', style: AppTextStyles.h3),
          ),
        ),

        // Lab result cards
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _LabResultCard(index: i, result: results[i]),
            childCount: results.length,
          ),
        ),

        // CTAs
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              children: [
                CuroButton(
                  label: 'Share Report',
                  variant: CuroButtonVariant.secondary,
                  icon: Icons.share_rounded,
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.s12),
                Consumer(
                  builder: (_, ref, _) => CuroButton(
                    label: 'Analyse Another Report',
                    variant: CuroButtonVariant.text,
                    onPressed: () =>
                        ref.read(reportProvider.notifier).reset(),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.icon,
    this.highlight = false,
  });
  final String label;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.orange.withValues(alpha: 0.20)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.r24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: highlight ? Colors.orange.shade300 : Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: highlight ? Colors.orange.shade300 : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lab Result Card ───────────────────────────────────────────────────────────

class _LabResultCard extends ConsumerWidget {
  const _LabResultCard({required this.index, required this.result});
  final int index;
  final LabResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref
        .watch(reportProvider.select((s) => s.expandedSet.contains(index)));
    final hasExplanation = result.aiExplanation != null;

    final (statusColor, statusBg, statusLabel) = switch (result.status) {
      LabStatus.high => (
          AppColors.danger,
          const Color(0xFFFEF2F2),
          'HIGH'
        ),
      LabStatus.low => (
          const Color(0xFFF59E0B),
          const Color(0xFFFFFBEB),
          'LOW'
        ),
      LabStatus.normal => (
          AppColors.success,
          const Color(0xFFF0FDF4),
          'NORMAL'
        ),
    };

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(
          color: result.status != LabStatus.normal
              ? statusColor.withValues(alpha: 0.30)
              : AppColors.border,
        ),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.testName, style: AppTextStyles.labelLarge),
                      const SizedBox(height: 4),
                      Text(result.refRangeLabel,
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: result.displayValue,
                            style: GoogleFonts.dmMono(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                          TextSpan(
                            text: ' ${result.unit}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(AppRadius.r4),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expandable AI explanation
          if (hasExplanation) ...[
            const Divider(height: 1, color: AppColors.border),
            InkWell(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.r12)),
              onTap: () =>
                  ref.read(reportProvider.notifier).toggleExpanded(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.s8),
                        Text(
                          'AI Explanation',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.primary),
                        ),
                        const Spacer(),
                        Icon(
                          expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: expanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s8),
                        child: Text(
                          result.aiExplanation!,
                          style: AppTextStyles.bodySmall
                              .copyWith(height: 1.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends ConsumerWidget {
  const _ErrorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(reportProvider.select((s) => s.error));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.danger, size: 40),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text('Analysis Failed', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.s8),
            Text(
              error ?? 'Something went wrong. Please try again.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s32),
            CuroButton(
              label: 'Try Again',
              onPressed: () => ref.read(reportProvider.notifier).reset(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashed Border Painter ─────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashW = 6.0;
    const dashSpace = 5.0;
    const radius = AppRadius.r16;
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.40)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(radius)));

    final metrics = path.computeMetrics().first;
    var distance = 0.0;
    while (distance < metrics.length) {
      canvas.drawPath(
        metrics.extractPath(
            distance, (distance + dashW).clamp(0, metrics.length)),
        paint,
      );
      distance += dashW + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
