import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/report_model.dart';
import '../models/report_models.dart';

void _showImageViewer(BuildContext context, String imageUrl) {
  showDialog<void>(
    context: context,
    builder: (_) => Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Report Image',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (_, _) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (_, _, _) => const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Read-only detail view for a historical [ReportModel] fetched from Firestore.
///
/// Does NOT route back to the scanner — this is purely for reviewing saved
/// results. The [report.analysisJson] is parsed via
/// [ReportAnalysisResult.fromJson] and rendered as expandable metric cards.
class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key, required this.report});

  final ReportModel report;

  ReportAnalysisResult? _tryParse(Map<String, dynamic> json) {
    try {
      return ReportAnalysisResult.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = report.analysisJson != null
        ? _tryParse(report.analysisJson!)
        : null;

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          report.name,
          style: AppTextStyles.h3,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: parsed != null
          ? _DetailBody(report: report, result: parsed)
          : _NoDataBody(report: report),
    );
  }
}

// ── Full detail view when analysisJson is available ───────────────────────────

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.report, required this.result});

  final ReportModel report;
  final ReportAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Patient meta header
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.meta.patientName,
                            style: AppTextStyles.labelLarge,
                          ),
                          Text(
                            '${result.meta.labName}  •  ${result.meta.date}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.r24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI Analysed',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: Divider(height: 1, color: AppColors.border),
        ),

        // AI Summary card — amber when alerts, primary when clean
        SliverToBoxAdapter(
          child: Builder(
            builder: (context) {
              final hasAlerts = result.summary.criticalAlerts > 0;
              final cardBg = hasAlerts
                  ? AppColors.warningBackground
                  : AppColors.primary;
              final labelColor = hasAlerts
                  ? AppColors.warningForeground.withValues(alpha: 0.70)
                  : AppColors.textPrimary.withValues(alpha: 0.65);
              final headlineColor = hasAlerts
                  ? AppColors.warningForeground
                  : AppColors.textPrimary;
              final bodyColor = hasAlerts
                  ? AppColors.warningForeground.withValues(alpha: 0.80)
                  : AppColors.textPrimary.withValues(alpha: 0.75);
              return Container(
                margin: const EdgeInsets.all(AppSpacing.s16),
                padding: const EdgeInsets.all(AppSpacing.s20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  border: hasAlerts
                      ? Border.all(
                          color: AppColors.warningForeground.withValues(
                            alpha: 0.22,
                          ),
                        )
                      : null,
                  boxShadow: AppShadows.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: labelColor,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Text(
                          'AI Summary',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: labelColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Text(
                      result.summary.headline,
                      style: AppTextStyles.h2.copyWith(color: headlineColor),
                    ),
                    if (result.summary.body.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        result.summary.body,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: bodyColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s16),
                    Row(
                      children: [
                        _SummaryChip(
                          label: '${result.summary.testsAnalyzed} Tests',
                          icon: Icons.science_rounded,
                          bg: hasAlerts
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.textPrimary.withValues(alpha: 0.10),
                          fg: hasAlerts
                              ? AppColors.primary
                              : AppColors.textPrimary.withValues(alpha: 0.65),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        _SummaryChip(
                          label: '${result.summary.criticalAlerts} Alerts',
                          icon: Icons.warning_amber_rounded,
                          bg: hasAlerts
                              ? AppColors.dangerBackground
                              : AppColors.textPrimary.withValues(alpha: 0.10),
                          fg: hasAlerts
                              ? AppColors.dangerForeground
                              : AppColors.textPrimary.withValues(alpha: 0.65),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Section header + View Image link
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              0,
              AppSpacing.s16,
              AppSpacing.s8,
            ),
            child: Row(
              children: [
                Text('Test Results', style: AppTextStyles.h3),
                const Spacer(),
                if (report.storageUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showImageViewer(context, report.storageUrl),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_search_outlined,
                          size: 15,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View Image',
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
          ),
        ),

        // Metric cards
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _DetailResultCard(result: result.results[i]),
            childCount: result.results.length,
          ),
        ),

        // Medical disclaimer
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s8,
              AppSpacing.s16,
              0,
            ),
            child: const _DisclaimerBanner(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s48)),
      ],
    );
  }
}

// ── Fallback when no analysisJson is stored ───────────────────────────────────

class _NoDataBody extends StatelessWidget {
  const _NoDataBody({required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              report.name,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Detailed analysis is not available for this record.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (report.aiSummary != null) ...[
              const SizedBox(height: AppSpacing.s16),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  report.aiSummary!,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (report.storageUrl.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s16),
              GestureDetector(
                onTap: () => _showImageViewer(context, report.storageUrl),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.r24),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_search_outlined,
                        size: 15,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'View Image',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Metric result card ────────────────────────────────────────────────────────

class _DetailResultCard extends StatelessWidget {
  const _DetailResultCard({required this.result});

  final LabResult result;

  bool get _isPrescriptionItem =>
      result.value == 0 && result.refRangeLow == 0 && result.refRangeHigh == 0;

  @override
  Widget build(BuildContext context) {
    if (_isPrescriptionItem) return _buildPrescriptionItem();

    final hasExplanation = result.aiExplanation?.isNotEmpty == true;

    final (statusColor, statusBg, statusLabel) = switch (result.status) {
      LabStatus.high => (
        AppColors.dangerForeground,
        AppColors.dangerBackground,
        'HIGH',
      ),
      LabStatus.low => (
        AppColors.warningForeground,
        AppColors.warningBackground,
        'LOW',
      ),
      LabStatus.normal => (
        AppColors.successForeground,
        AppColors.successBackground,
        'NORMAL',
      ),
    };

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
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
                      Text(
                        result.refRangeLabel,
                        style: AppTextStyles.bodySmall,
                      ),
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
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(AppRadius.r24),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.22),
                        ),
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
          if (hasExplanation) ...[
            const Divider(height: 1, color: AppColors.border),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: 0,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  0,
                  AppSpacing.s16,
                  AppSpacing.s12,
                ),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                leading: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                title: Text(
                  'AI Explanation',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                iconColor: AppColors.textSecondary,
                collapsedIconColor: AppColors.textSecondary,
                shape: const Border(),
                collapsedShape: const Border(),
                children: [
                  Text(
                    result.aiExplanation!,
                    style: AppTextStyles.bodySmall.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrescriptionItem() {
    final hasExplanation = result.aiExplanation?.isNotEmpty == true;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.testName, style: AppTextStyles.labelLarge),
                if (hasExplanation) ...[
                  const SizedBox(height: 4),
                  Text(
                    result.aiExplanation!,
                    style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary chip ──────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: fg)),
        ],
      ),
    );
  }
}

// ── Medical disclaimer banner ─────────────────────────────────────────────────

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(
          color: AppColors.warningForeground.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.warningForeground,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical Disclaimer',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.warningForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'These results are AI-generated and intended for informational '
                  'purposes only. They do not constitute medical advice, '
                  'diagnosis, or treatment. Always consult a qualified healthcare '
                  'professional before making any health decisions.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warningForeground,
                    height: 1.5,
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
