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
import '../models/lab_booking_models.dart';
import '../providers/lab_booking_provider.dart';
import '../providers/lab_map_provider.dart';

class LabBookingScreen extends ConsumerStatefulWidget {
  const LabBookingScreen({
    super.key,
    required this.lab,
    required this.test,
  });

  final LabLocation lab;
  final LabTest test;

  @override
  ConsumerState<LabBookingScreen> createState() => _LabBookingScreenState();
}

class _LabBookingScreenState extends ConsumerState<LabBookingScreen> {
  late DateTime _selectedDate;
  TimeSlot? _selectedSlot;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _confirmBooking() {
    if (_selectedSlot == null) return;
    final booking = MyBooking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      labId: widget.lab.id,
      labName: widget.lab.name,
      labColor: widget.lab.avatarColor,
      testName: widget.test.name,
      date: _selectedDate,
      timeSlot: _selectedSlot!.label,
      priceRs: widget.test.priceRs,
      status: BookingStatus.upcoming,
    );
    ref.read(myBookingsProvider.notifier).add(booking);
    setState(() => _isConfirmed = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _isConfirmed
          ? null
          : CuroAppBar(title: 'Book Test'),
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
                        AppSpacing.s16, AppSpacing.s12,
                        AppSpacing.s16, AppSpacing.s16),
                    child: CuroButton(
                      label: _selectedSlot == null
                          ? 'Select a Time Slot'
                          : 'Confirm Booking  ·  ₨ ${widget.test.priceRs}',
                      onPressed: _selectedSlot != null ? _confirmBooking : null,
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF36BDF2), Color(0xFF0D7AB5)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.science_rounded, color: Colors.white, size: 26),
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
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.white.withValues(alpha: 0.85)),
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
                          ? Colors.white.withValues(alpha: 0.85)
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
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: kBookingTimeSlots
          .map((slot) => _TimeChip(
                slot: slot,
                isSelected: selected?.id == slot.id,
                onTap: slot.isAvailable ? () => onSelect(slot) : null,
              ))
          .toList(),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : unavailable
                  ? AppColors.background
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          slot.label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected
                ? Colors.white
                : unavailable
                    ? AppColors.textSecondary.withValues(alpha: 0.45)
                    : AppColors.textPrimary,
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
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  size: 44,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Text('Booking Confirmed!', style: AppTextStyles.h2),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Your test has been scheduled successfully.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s32),

              // Booking detail card
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.sm,
                ),
                child: Column(
                  children: [
                    _ConfirmRow(Icons.science_rounded, 'Lab', lab.name),
                    const Divider(height: 1, color: AppColors.border),
                    _ConfirmRow(Icons.biotech_rounded, 'Test', test.name),
                    const Divider(height: 1, color: AppColors.border),
                    _ConfirmRow(
                      Icons.calendar_today_outlined,
                      'Date',
                      DateFormat('EEE, d MMM yyyy').format(date),
                    ),
                    if (slot != null) ...[
                      const Divider(height: 1, color: AppColors.border),
                      _ConfirmRow(
                          Icons.access_time_rounded, 'Time', slot!.label),
                    ],
                    const Divider(height: 1, color: AppColors.border),
                    _ConfirmRow(
                        Icons.payments_outlined, 'Price', '₨ ${test.priceRs}'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s24),

              CuroButton(
                label: 'View My Bookings',
                onPressed: () => context.push(AppRoutes.myBookings),
              ),
              const SizedBox(height: AppSpacing.s12),
              CuroButton(
                label: 'Back to Home',
                variant: CuroButtonVariant.secondary,
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
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
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s8),
          Text(
            label,
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(value, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}
