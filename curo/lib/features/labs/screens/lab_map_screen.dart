import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/curo_bottom_nav_bar.dart';
import '../../../core/widgets/curo_button.dart';
import '../providers/lab_map_provider.dart';

class LabMapScreen extends ConsumerStatefulWidget {
  const LabMapScreen({super.key});

  @override
  ConsumerState<LabMapScreen> createState() => _LabMapScreenState();
}

class _LabMapScreenState extends ConsumerState<LabMapScreen> {
  final MapController _mapController = MapController();
  String? _selectedLabId;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  static const _defaultCenter = LatLng(24.8607, 67.0011);
  static const _defaultZoom = 13.5;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _mapController.move(_defaultCenter, _defaultZoom);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
    } catch (_) {
      _mapController.move(_defaultCenter, _defaultZoom);
    }
  }

  void _onNavTap(int i) {
    if (i == 0) context.go(AppRoutes.home);
    if (i == 2) context.go(AppRoutes.reports);
    if (i == 3) context.go(AppRoutes.medicines);
    if (i == 4) context.go(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    final labs = ref.watch(filteredLabsProvider);

    return Scaffold(
      body: Stack(
        children: [
          // ── OpenStreetMap (free, no API key) ─────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              onTap: (tapPos, point) => setState(() => _selectedLabId = null),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.curo.healthcare.pk',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: labs
                    .map(
                      (lab) => Marker(
                        point: LatLng(lab.lat, lab.lng),
                        width: 84,
                        height: 50,
                        alignment: Alignment.bottomCenter,
                        child: _PriceMarker(
                          price: lab.startingPriceRs,
                          selected: lab.id == _selectedLabId,
                          onTap: () {
                            setState(() => _selectedLabId = lab.id);
                            _sheetController.animateTo(
                              0.48,
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOut,
                            );
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),

          // ── Search bar + filter pills ─────────────────────────────────────
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 0),
                  child: _SearchBar(),
                ),
                const SizedBox(height: AppSpacing.s8),
                _FilterRow(),
              ],
            ),
          ),

          // ── My-location FAB ───────────────────────────────────────────────
          Positioned(
            right: AppSpacing.s16,
            bottom: 300,
            child: GestureDetector(
              onTap: _goToMyLocation,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.md,
                ),
                child: const Icon(Icons.my_location_rounded,
                    size: 20, color: AppColors.primary),
              ),
            ),
          ),

          // ── Draggable bottom sheet ────────────────────────────────────────
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.40,
            minChildSize: 0.22,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.22, 0.40, 0.88],
            builder: (_, scrollController) => _LabListSheet(
              scrollController: scrollController,
              labs: labs,
              selectedLabId: _selectedLabId,
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          CuroBottomNavBar(currentIndex: 1, onTap: _onNavTap),
    );
  }
}

// ── Price Marker (Flutter widget — no async bitmap needed) ────────────────────

class _PriceMarker extends StatelessWidget {
  const _PriceMarker({
    required this.price,
    required this.selected,
    required this.onTap,
  });
  final int price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF1A9AD4) : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Rs $price',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(14, 7),
            painter: _TrianglePainter(color: color),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r24),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.s16),
          const Icon(Icons.search_rounded,
              size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search labs, tests, areas...',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Container(width: 1, height: 24, color: AppColors.border),
          const SizedBox(width: AppSpacing.s12),
          const Icon(Icons.tune_rounded,
              size: 20, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.s16),
        ],
      ),
    );
  }
}

// ── Filter Pills ──────────────────────────────────────────────────────────────

class _FilterRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(labFilterProvider);
    const filters = [
      (LabFilter.all, 'All'),
      (LabFilter.nearest, 'Nearest'),
      (LabFilter.cheapest, 'Cheapest'),
      (LabFilter.highestRated, 'Highest Rated'),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        itemCount: filters.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppSpacing.s8),
        itemBuilder: (_, i) {
          final (filter, label) = filters[i];
          final active = current == filter;
          return GestureDetector(
            onTap: () =>
                ref.read(labFilterProvider.notifier).set(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFEBF8FE)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.r24),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                  width: active ? 1.5 : 1,
                ),
                boxShadow: active ? null : AppShadows.sm,
              ),
              child: Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: active
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Lab List Sheet ────────────────────────────────────────────────────────────

class _LabListSheet extends StatelessWidget {
  const _LabListSheet({
    required this.scrollController,
    required this.labs,
    this.selectedLabId,
  });
  final ScrollController scrollController;
  final List<LabLocation> labs;
  final String? selectedLabId;

  @override
  Widget build(BuildContext context) {
    final sorted = selectedLabId != null
        ? [
            ...labs.where((l) => l.id == selectedLabId),
            ...labs.where((l) => l.id != selectedLabId),
          ]
        : labs;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, -4))
        ],
      ),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.s12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16),
                  child: Text('${labs.length} labs found nearby',
                      style: AppTextStyles.h3),
                ),
                const SizedBox(height: AppSpacing.s12),
                const Divider(height: 1, color: AppColors.border),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _LabListCard(
                lab: sorted[i],
                isSelected: sorted[i].id == selectedLabId,
              ),
              childCount: sorted.length,
            ),
          ),
          const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.s24)),
        ],
      ),
    );
  }
}

// ── Lab List Card ─────────────────────────────────────────────────────────────

class _LabListCard extends StatelessWidget {
  const _LabListCard({required this.lab, required this.isSelected});
  final LabLocation lab;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.04)
            : Colors.transparent,
        border: isSelected
            ? const Border(
                left: BorderSide(color: AppColors.primary, width: 3))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: lab.avatarColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.science_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lab.name, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(lab.address, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        '${lab.rating} (${lab.reviewCount})',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Starts Rs ${lab.startingPriceRs}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            CuroButton(
              label: 'Book',
              width: 72,
              onPressed: () =>
                  context.push(AppRoutes.labDetail, extra: lab),
            ),
          ],
        ),
      ),
    );
  }
}
