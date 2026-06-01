import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/curo_app_bar.dart';
import '../../../core/widgets/curo_button.dart';
import '../../../providers/booking_provider.dart';
import '../models/lab_booking_models.dart';
import '../providers/lab_map_provider.dart';

class LabBookingScreen extends ConsumerStatefulWidget {
  const LabBookingScreen({super.key, required this.lab, required this.test});

  final LabLocation lab;
  final LabTest test;

  @override
  ConsumerState<LabBookingScreen> createState() => _LabBookingScreenState();
}

class _LabBookingScreenState extends ConsumerState<LabBookingScreen> {
  late DateTime _selectedDate;
  TimeSlot? _selectedSlot;
  bool _isConfirmed = false;
  bool _isBookingLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlot == null || _isBookingLoading) return;
    setState(() => _isBookingLoading = true);
    final booking = await ref
        .read(bookingCreateProvider.notifier)
        .createBooking(
          labId: widget.lab.id,
          labName: widget.lab.name,
          testName: widget.test.name,
          date: _selectedDate,
          timeSlot: _selectedSlot!.label,
          priceRs: widget.test.priceRs,
        );
    if (!mounted) return;
    if (booking != null) {
      setState(() {
        _isBookingLoading = false;
        _isConfirmed = true;
      });
    } else {
      setState(() => _isBookingLoading = false);
      final error =
          ref.read(bookingCreateProvider).error ?? 'Booking failed. Try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _isConfirmed ? null : CuroAppBar(title: 'Book Test'),
      body: _isConfirmed
          ? _SuccessView(
              lab: widget.lab,
              test: widget.test,
              date: _selectedDate,
              slot: _selectedSlot,
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummaryCard(lab: widget.lab, test: widget.test),
                        const SizedBox(height: AppSpacing.s24),
                        _sectionLabel('Select Date'),
                        const SizedBox(height: AppSpacing.s12),
                        _DateRow(
                          selected: _selectedDate,
                          onSelect: (d) => setState(() {
                            _selectedDate = d;
                            _selectedSlot = null;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.s24),
                        _sectionLabel('Select Time Slot'),
                        const SizedBox(height: AppSpacing.s12),
                        _TimeGrid(
                          selected: _selectedSlot,
                          onSelect: (s) => setState(() => _selectedSlot = s),
                        ),
                        const SizedBox(height: AppSpacing.s32),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      AppSpacing.s12,
                      AppSpacing.s16,
                      AppSpacing.s16,
                    ),
                    child: CuroButton(
                      label: _selectedSlot == null
                          ? 'Select a Time Slot'
                          : 'Confirm Booking  ·  Rs ${widget.test.priceRs}',
                      isLoading: _isBookingLoading,
                      onPressed: (_selectedSlot != null && !_isBookingLoading)
                          ? _confirmBooking
                          : null,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: AppTextStyles.h3);
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.lab, required this.test});

  final LabLocation lab;
  final LabTest test;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.biotech_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lab.name,
                  style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  test.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₨ ${test.priceRs}',
            style: AppTextStyles.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date Row ──────────────────────────────────────────────────────────────────

class _DateRow extends StatelessWidget {
  const _DateRow({required this.selected, required this.onSelect});

  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return SizedBox(
      height: 82,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (_, i) {
          final date = today.add(Duration(days: i));
          final isSelected = _sameDay(date, selected);
          final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final dayLabel = dayNames[date.weekday - 1];

          return GestureDetector(
            onTap: () => onSelect(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              margin: const EdgeInsets.only(right: AppSpacing.s8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.r16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected ? AppShadows.md : AppShadows.sm,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    i == 0 ? 'Today' : dayLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected
                          ? Colors.white70
                          : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: AppTextStyles.h3.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Time Grid ─────────────────────────────────────────────────────────────────

class _TimeGrid extends StatelessWidget {
  const _TimeGrid({required this.selected, required this.onSelect});

  final TimeSlot? selected;
  final ValueChanged<TimeSlot> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.s8,
        mainAxisSpacing: AppSpacing.s8,
        childAspectRatio: 2.6,
      ),
      itemCount: kBookingTimeSlots.length,
      itemBuilder: (_, i) {
        final slot = kBookingTimeSlots[i];
        return _TimeSlotCell(
          slot: slot,
          isSelected: selected?.id == slot.id,
          onTap: slot.isAvailable ? () => onSelect(slot) : null,
        );
      },
    );
  }
}

class _TimeSlotCell extends StatelessWidget {
  const _TimeSlotCell({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  final TimeSlot slot;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unavailable = !slot.isAvailable;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : unavailable
                ? AppColors.border.withValues(alpha: 0.50)
                : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? AppShadows.md : const [],
        ),
        child: Center(
          child: Text(
            slot.label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected
                  ? Colors.white
                  : unavailable
                  ? AppColors.textSecondary.withValues(alpha: 0.40)
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Success View ──────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.lab,
    required this.test,
    required this.date,
    required this.slot,
  });

  final LabLocation lab;
  final LabTest test;
  final DateTime date;
  final TimeSlot? slot;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s24,
          vertical: AppSpacing.s32,
        ),
        child: Column(
          children: [
            // ── Success Banner — concentric ring vector ──────────────────────
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulse ring
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    color: AppColors.successForeground.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                  ),
                ),
                // Middle ring
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.successForeground.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
                // Inner filled circle + check icon
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: AppColors.successBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.successForeground,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),

            Text(
              'Booking Confirmed!',
              style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Your test has been scheduled successfully.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s32),

            // ── Transaction Invoice Block ────────────────────────────────────
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.r16),
                boxShadow: AppShadows.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Receipt header strip
                  Container(
                    color: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Text(
                          'BOOKING RECEIPT',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Itemised data rows
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      AppSpacing.s8,
                      AppSpacing.s16,
                      AppSpacing.s8,
                    ),
                    child: Column(
                      children: [
                        _ConfirmRow(Icons.science_rounded, 'Lab', lab.name),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border,
                        ),
                        _ConfirmRow(Icons.biotech_rounded, 'Test', test.name),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border,
                        ),
                        _ConfirmRow(
                          Icons.calendar_today_outlined,
                          'Date',
                          DateFormat('EEE, d MMM yyyy').format(date),
                        ),
                        if (slot != null) ...[
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border,
                          ),
                          _ConfirmRow(
                            Icons.access_time_rounded,
                            'Time',
                            slot!.label,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Price footer — success-tinted, full-width
                  Container(
                    color: AppColors.successBackground,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s16,
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Amount',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.successForeground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Payable at lab',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.successForeground.withValues(
                                  alpha: 0.60,
                                ),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '₨ ${test.priceRs}',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.successForeground,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),

            // ── Action Triggers ──────────────────────────────────────────────

            // Primary — full-width accent CTA
            GestureDetector(
              onTap: () => context.push(AppRoutes.myBookings),
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      'View My Bookings',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Secondary — minimalist text link
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s12,
                ),
                minimumSize: const Size(double.infinity, 44),
              ),
              child: Text(
                'Back to Home',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
