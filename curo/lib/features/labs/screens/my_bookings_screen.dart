import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/curo_app_bar.dart';
import '../../../data/models/booking_model.dart';
import '../../../providers/booking_provider.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncBookings = ref.watch(userBookingsProvider);

    return asyncBookings.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: CuroAppBar(title: 'My Bookings'),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: CuroAppBar(title: 'My Bookings'),
        body: Center(
          child: Text(
            'Could not load bookings.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
      data: (all) {
        final upcoming = all.where((b) => b.status == 'upcoming').toList();
        final past = all.where((b) => b.status != 'upcoming').toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CuroAppBar(
            title: 'My Bookings',
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: AppTextStyles.labelLarge,
              unselectedLabelStyle: AppTextStyles.labelLarge,
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _BookingsList(
                bookings: upcoming,
                emptyMessage: 'No upcoming bookings',
              ),
              _BookingsList(bookings: past, emptyMessage: 'No past bookings'),
            ],
          ),
        );
      },
    );
  }
}

// ── Bookings List ─────────────────────────────────────────────────────────────

class _BookingsList extends StatelessWidget {
  const _BookingsList({required this.bookings, required this.emptyMessage});

  final List<BookingModel> bookings;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 52,
              color: AppColors.border,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              emptyMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.s16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
    );
  }
}

// ── Booking Card ──────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final BookingModel booking;

  Color _statusColor() => switch (booking.status) {
    'upcoming' => AppColors.primary,
    'completed' => AppColors.success,
    _ => AppColors.textSecondary,
  };

  String _statusLabel() => switch (booking.status) {
    'upcoming' => 'Upcoming',
    'completed' => 'Completed',
    _ => 'Cancelled',
  };

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, d MMM yyyy');
    final statusColor = _statusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.labName, style: AppTextStyles.labelLarge),
                    const SizedBox(height: 2),
                    Text(
                      booking.testName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.r24),
                ),
                child: Text(
                  _statusLabel(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              _DetailItem(
                icon: Icons.calendar_today_outlined,
                text: dateFmt.format(booking.date),
              ),
              const SizedBox(width: AppSpacing.s16),
              _DetailItem(
                icon: Icons.access_time_rounded,
                text: booking.timeSlot,
              ),
              const Spacer(),
              Text(
                'Rs ${booking.priceRs}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
