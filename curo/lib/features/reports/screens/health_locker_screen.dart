import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/curo_bottom_nav_bar.dart';
import '../../../core/widgets/status_chip.dart';
import '../models/health_locker_models.dart';
import '../providers/health_locker_provider.dart';

class HealthLockerScreen extends ConsumerStatefulWidget {
  const HealthLockerScreen({super.key});

  @override
  ConsumerState<HealthLockerScreen> createState() => _HealthLockerScreenState();
}

class _HealthLockerScreenState extends ConsumerState<HealthLockerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _categories = ReportCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref
          .read(healthLockerProvider.notifier)
          .selectCategory(_categories[_tabController.index]);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthLockerProvider);
    final notifier = ref.read(healthLockerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.s16,
        title: Text('Health Locker', style: AppTextStyles.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            color: AppColors.textPrimary,
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              state.isGridView
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
            ),
            color: AppColors.textPrimary,
            onPressed: notifier.toggleView,
          ),
          const SizedBox(width: AppSpacing.s4),
        ],
      ),
      body: Column(
        children: [
          _CategoryTabBar(controller: _tabController),
          Expanded(
            child: state.filtered.isEmpty
                ? const _EmptyState()
                : _ReportContent(state: state),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRoutes.reportUpload),
        backgroundColor: AppColors.primary,
        elevation: 6,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: CuroBottomNavBar(
        currentIndex: 2,
        onTap: (i) {
          if (i == 0) context.go(AppRoutes.home);
          if (i == 1) context.go(AppRoutes.labs);
          if (i == 3) context.go(AppRoutes.medicines);
          if (i == 4) context.go(AppRoutes.profile);
        },
      ),
    );
  }
}

// ── Category Tab Bar ──────────────────────────────────────────────────────────

class _CategoryTabBar extends StatelessWidget {
  const _CategoryTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.border,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
        tabs: ReportCategory.values.map((c) => Tab(text: c.label)).toList(),
      ),
    );
  }
}

// ── Report Content ────────────────────────────────────────────────────────────

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.state});

  final HealthLockerState state;

  @override
  Widget build(BuildContext context) {
    final reports = state.filtered;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s16,
            AppSpacing.s16,
            0,
          ),
          sliver: state.isGridView
              ? SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _GridReportCard(report: reports[i]),
                    childCount: reports.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.s12,
                    crossAxisSpacing: AppSpacing.s12,
                    childAspectRatio: 0.85,
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                      child: _ListReportCard(report: reports[i]),
                    ),
                    childCount: reports.length,
                  ),
                ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s16,
            AppSpacing.s16,
            100,
          ),
          sliver: SliverToBoxAdapter(child: _AiTrendCard()),
        ),
      ],
    );
  }
}

// ── Grid Card ─────────────────────────────────────────────────────────────────

class _GridReportCard extends StatelessWidget {
  const _GridReportCard({required this.report});

  final LockerReport report;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.reportUpload),
      child: Container(
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: report.iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(report.icon, color: report.iconColor, size: 24),
            ),
            const Spacer(),
            Text(
              report.name,
              style: AppTextStyles.labelLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(report.date, style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSpacing.s8),
            StatusChip(label: report.statusLabel, variant: report.status),
          ],
        ),
      ),
    );
  }
}

// ── List Card ─────────────────────────────────────────────────────────────────

class _ListReportCard extends StatelessWidget {
  const _ListReportCard({required this.report});

  final LockerReport report;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.reportUpload),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: report.iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(report.icon, color: report.iconColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.s12),
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

// ── AI Trend Card ─────────────────────────────────────────────────────────────

class _AiTrendCard extends StatelessWidget {
  const _AiTrendCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A5F7A),
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.r24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'HEALTH AI',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Trend Detected',
            style: AppTextStyles.h3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Your iron levels have improved by 12% since your last CBC in '
            'August. Keep up the dietary plan.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text('No reports yet.', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Upload your first report.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
