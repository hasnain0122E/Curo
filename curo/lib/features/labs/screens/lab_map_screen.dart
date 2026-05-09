import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/curo_bottom_nav_bar.dart';
import '../../../core/widgets/curo_button.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/overpass_service.dart';
import '../../../features/home/providers/home_provider.dart';
import '../../../providers/lab_provider.dart';
import '../../../providers/pharmacy_provider.dart';
import '../providers/lab_map_provider.dart';

class LabMapScreen extends ConsumerStatefulWidget {
  const LabMapScreen({super.key});

  @override
  ConsumerState<LabMapScreen> createState() => _LabMapScreenState();
}

class _LabMapScreenState extends ConsumerState<LabMapScreen> {
  final MapController _mapController = MapController();
  String? _selectedId;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  static const _defaultCenter = LatLng(24.8607, 67.0011);
  static const _defaultZoom = 13.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnUser());
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _centerOnUser() async {
    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;
    if (pos != null) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 14.0);
    }
  }

  Future<void> _goToMyLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;
    _mapController.move(
      pos != null ? LatLng(pos.latitude, pos.longitude) : _defaultCenter,
      pos != null ? 15.0 : _defaultZoom,
    );
  }

  void _moveToItem(double lat, double lng) =>
      _mapController.move(LatLng(lat, lng), 14.5);

  /// Shows the detail modal for a tapped OSM POI.
  void _showOsmSheet(OsmPlace place) {
    // Find the closest Firebase lab/pharmacy to this OSM place (< 1 km = bookable)
    final allLabs = ref.read(allLabsProvider);
    final allPharmacies = ref.read(allPharmaciesProvider);

    LabLocation? matchedLab;
    PharmacyLocation? matchedPharmacy;

    for (final lab in allLabs) {
      if (LocationService.distanceKm(place.lat, place.lng, lab.lat, lab.lng) <
          1.0) {
        matchedLab = lab;
        break;
      }
    }
    if (matchedLab == null) {
      for (final p in allPharmacies) {
        if (LocationService.distanceKm(place.lat, place.lng, p.lat, p.lng) <
            1.0) {
          matchedPharmacy = p;
          break;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OsmPlaceSheet(
        place: place,
        matchedLab: matchedLab,
        matchedPharmacy: matchedPharmacy,
      ),
    );
  }

  void _onNavTap(int i) {
    if (i == 0) context.go(AppRoutes.home);
    if (i == 2) context.go(AppRoutes.reports);
    if (i == 3) context.go(AppRoutes.medicines);
    if (i == 4) context.go(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(mapModeProvider);
    final labsAsync = ref.watch(labsStreamProvider);
    final pharmaciesAsync = ref.watch(pharmaciesStreamProvider);
    final labs = ref.watch(filteredLabsProvider);
    final pharmacies = ref.watch(filteredPharmaciesProvider);
    final osmAsync = ref.watch(osmPlacesProvider);
    final osmPlaces = osmAsync.asData?.value ?? [];

    final isLoading =
        mode == MapMode.labs ? labsAsync.isLoading : pharmaciesAsync.isLoading;
    final hasError =
        mode == MapMode.labs ? labsAsync.hasError : pharmaciesAsync.hasError;

    // Clear selection when mode changes
    ref.listen<MapMode>(mapModeProvider, (prev, next) {
      if (prev != next) setState(() => _selectedId = null);
    });

    // Animate map to top result when filter changes (non-All filters)
    ref.listen<LabFilter>(labFilterProvider, (prev, next) {
      if (prev != next && next != LabFilter.all) {
        final filtered = ref.read(filteredLabsProvider);
        if (filtered.isNotEmpty) _moveToItem(filtered.first.lat, filtered.first.lng);
      }
    });
    ref.listen<PharmacyFilter>(pharmacyFilterProvider, (prev, next) {
      if (prev != next && next != PharmacyFilter.all) {
        final filtered = ref.read(filteredPharmaciesProvider);
        if (filtered.isNotEmpty) _moveToItem(filtered.first.lat, filtered.first.lng);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              onTap: (_, _) => setState(() => _selectedId = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.curo.healthcare.pk',
                maxZoom: 19,
              ),

              // ── Layer 1: OSM real-world places (background, smaller) ────────
              // Shown beneath Firebase markers so our bookable labs stay on top.
              // Filtered by mode: labs mode shows hospitals/clinics/labs;
              // pharmacies mode shows OSM pharmacies.
              MarkerLayer(
                markers: osmPlaces
                    .where((p) => mode == MapMode.labs
                        ? p.amenity != OsmAmenity.pharmacy
                        : p.amenity == OsmAmenity.pharmacy)
                    .map((place) => Marker(
                          point: LatLng(place.lat, place.lng),
                          width: 34,
                          height: 34,
                          child: _OsmMarker(
                            place: place,
                            onTap: () => _showOsmSheet(place),
                          ),
                        ))
                    .toList(),
              ),

              // ── Layer 2: Firebase bookable markers (foreground, larger) ─────
              if (mode == MapMode.labs)
                MarkerLayer(
                  markers: labs
                      .map((lab) => Marker(
                            point: LatLng(lab.lat, lab.lng),
                            width: 88,
                            height: 52,
                            alignment: Alignment.bottomCenter,
                            child: _PriceMarker(
                              price: lab.startingPriceRs,
                              selected: lab.id == _selectedId,
                              onTap: () {
                                setState(() => _selectedId = lab.id);
                                _sheetController.animateTo(0.48,
                                    duration:
                                        const Duration(milliseconds: 320),
                                    curve: Curves.easeOut);
                              },
                            ),
                          ))
                      .toList(),
                )
              else
                MarkerLayer(
                  markers: pharmacies
                      .map((p) => Marker(
                            point: LatLng(p.lat, p.lng),
                            width: 44,
                            height: 52,
                            alignment: Alignment.bottomCenter,
                            child: _PharmacyMarker(
                              selected: p.id == _selectedId,
                              is24h: p.is24Hours,
                              onTap: () {
                                setState(() => _selectedId = p.id);
                                _sheetController.animateTo(0.48,
                                    duration:
                                        const Duration(milliseconds: 320),
                                    curve: Curves.easeOut);
                              },
                            ),
                          ))
                      .toList(),
                ),
            ],
          ),

          // ── Loading overlay ────────────────────────────────────────────────
          if (isLoading)
            const Center(child: CircularProgressIndicator()),

          // ── Error banner ───────────────────────────────────────────────────
          if (hasError)
            Positioned(
              top: 80,
              left: AppSpacing.s16,
              right: AppSpacing.s16,
              child: Material(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(AppRadius.r12),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.s12),
                  child: Text(
                    'Could not load data. Check connection & Firestore rules.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),

          // ── Search bar + filter pills ──────────────────────────────────────
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 0),
                  child: const _SearchBar(),
                ),
                const SizedBox(height: AppSpacing.s8),
                const _FilterRow(),
              ],
            ),
          ),

          // ── My-location FAB ────────────────────────────────────────────────
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

          // ── Draggable bottom sheet ─────────────────────────────────────────
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.40,
            minChildSize: 0.22,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.22, 0.40, 0.88],
            builder: (_, scrollController) => _ListSheet(
              scrollController: scrollController,
              labs: labs,
              pharmacies: pharmacies,
              selectedId: _selectedId,
            ),
          ),
        ],
      ),
      bottomNavigationBar: CuroBottomNavBar(currentIndex: 1, onTap: _onNavTap),
    );
  }
}

// ── Lab price marker ──────────────────────────────────────────────────────────

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

// ── Pharmacy map marker ───────────────────────────────────────────────────────

class _PharmacyMarker extends StatelessWidget {
  const _PharmacyMarker({
    required this.selected,
    required this.is24h,
    required this.onTap,
  });
  final bool selected;
  final bool is24h;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF0F9B58) : const Color(0xFF22C55E);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.local_pharmacy_rounded,
                    color: Colors.white, size: 18),
              ),
              if (is24h)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('24H',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
          CustomPaint(
            size: const Size(10, 5),
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

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sync external resets (e.g. mode toggle clears labSearchProvider)
    ref.listen<String>(labSearchProvider, (_, next) {
      if (next.isEmpty && _controller.text.isNotEmpty) {
        _controller.clear();
      }
    });

    final mode = ref.watch(mapModeProvider);
    final hint = mode == MapMode.labs
        ? 'Search labs, tests, cities...'
        : 'Search pharmacies, cities...';

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
              controller: _controller,
              onChanged: (v) =>
                  ref.read(labSearchProvider.notifier).set(v),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTextStyles.bodyMedium,
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                ref.read(labSearchProvider.notifier).set('');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                child: Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textSecondary),
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

// ── Filter pills (mode-aware) ─────────────────────────────────────────────────

class _FilterRow extends ConsumerWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(mapModeProvider);
    return mode == MapMode.labs
        ? _LabFilterPills()
        : _PharmacyFilterPills();
  }
}

class _LabFilterPills extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(labFilterProvider);
    const items = [
      (LabFilter.all, 'All', Icons.apps_rounded),
      (LabFilter.nearest, 'Nearest', Icons.near_me_rounded),
      (LabFilter.cheapest, 'Cheapest', Icons.attach_money_rounded),
      (LabFilter.highestRated, 'Top Rated', Icons.star_rounded),
    ];
    return _FilterPillRow<LabFilter>(
      items: items,
      current: current,
      onTap: (f) => ref.read(labFilterProvider.notifier).set(f),
    );
  }
}

class _PharmacyFilterPills extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(pharmacyFilterProvider);
    const items = [
      (PharmacyFilter.all, 'All', Icons.apps_rounded),
      (PharmacyFilter.nearest, 'Nearest', Icons.near_me_rounded),
      (PharmacyFilter.open24h, 'Open 24H', Icons.access_time_rounded),
      (PharmacyFilter.highestRated, 'Top Rated', Icons.star_rounded),
    ];
    return _FilterPillRow<PharmacyFilter>(
      items: items,
      current: current,
      onTap: (f) => ref.read(pharmacyFilterProvider.notifier).set(f),
    );
  }
}

class _FilterPillRow<T> extends StatelessWidget {
  const _FilterPillRow({
    required this.items,
    required this.current,
    required this.onTap,
  });
  final List<(T, String, IconData)> items;
  final T current;
  final void Function(T) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppSpacing.s8),
        itemBuilder: (_, i) {
          final (filter, label, icon) = items[i];
          final active = current == filter;
          return GestureDetector(
            onTap: () => onTap(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 13,
                      color: active
                          ? AppColors.primary
                          : AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: active
                          ? AppColors.primary
                          : AppColors.textSecondary,
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

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _ListSheet extends ConsumerWidget {
  const _ListSheet({
    required this.scrollController,
    required this.labs,
    required this.pharmacies,
    this.selectedId,
  });
  final ScrollController scrollController;
  final List<LabLocation> labs;
  final List<PharmacyLocation> pharmacies;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(mapModeProvider);
    final labFilter = ref.watch(labFilterProvider);
    final pharmFilter = ref.watch(pharmacyFilterProvider);

    final isLabs = mode == MapMode.labs;
    final count = isLabs ? labs.length : pharmacies.length;
    final isEmpty = count == 0;

    // When selected, bubble that item to the top
    final sortedLabs = selectedId != null && isLabs
        ? [
            ...labs.where((l) => l.id == selectedId),
            ...labs.where((l) => l.id != selectedId),
          ]
        : labs;
    final sortedPharm = selectedId != null && !isLabs
        ? [
            ...pharmacies.where((p) => p.id == selectedId),
            ...pharmacies.where((p) => p.id != selectedId),
          ]
        : pharmacies;

    // Badge label for top item
    String? topBadge;
    if (!isEmpty && selectedId == null) {
      if (isLabs) {
        topBadge = switch (labFilter) {
          LabFilter.nearest => 'NEAREST',
          LabFilter.cheapest => 'CHEAPEST',
          LabFilter.highestRated => 'BEST RATED',
          _ => null,
        };
      } else {
        topBadge = switch (pharmFilter) {
          PharmacyFilter.nearest => 'NEAREST',
          PharmacyFilter.open24h => 'OPEN 24H',
          PharmacyFilter.highestRated => 'BEST RATED',
          _ => null,
        };
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, -4)),
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
                // Handle bar
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
                const SizedBox(height: AppSpacing.s12),
                // Labs / Pharmacies toggle
                const _MapModeToggle(),
                const SizedBox(height: AppSpacing.s12),
                // Count heading
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16),
                  child: Text(
                    isEmpty
                        ? 'No ${isLabs ? 'labs' : 'pharmacies'} found'
                        : '$count ${isLabs ? 'lab' : 'pharmac'}${isLabs ? (count == 1 ? '' : 's') : (count == 1 ? 'y' : 'ies')} nearby',
                    style: AppTextStyles.h3,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                const Divider(height: 1, color: AppColors.border),
              ],
            ),
          ),
          if (isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLabs
                          ? Icons.science_outlined
                          : Icons.local_pharmacy_outlined,
                      size: 52,
                      color: AppColors.border,
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Text(
                      isLabs
                          ? 'No labs found. Try a different search or filter.'
                          : 'No pharmacies found. Try a different search or filter.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else if (isLabs)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _LabListCard(
                  lab: sortedLabs[i],
                  isSelected: sortedLabs[i].id == selectedId,
                  badge: i == 0 && selectedId == null ? topBadge : null,
                ),
                childCount: sortedLabs.length,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _PharmacyCard(
                  pharmacy: sortedPharm[i],
                  isSelected: sortedPharm[i].id == selectedId,
                  badge: i == 0 && selectedId == null ? topBadge : null,
                ),
                childCount: sortedPharm.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s24)),
        ],
      ),
    );
  }
}

// ── Map mode toggle (inside sheet) ────────────────────────────────────────────

class _MapModeToggle extends ConsumerWidget {
  const _MapModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(mapModeProvider);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: MapMode.values.map((m) {
          final active = m == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(mapModeProvider.notifier).set(m);
                ref.read(labSearchProvider.notifier).set('');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  color: active ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: active ? AppShadows.sm : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      m == MapMode.labs
                          ? Icons.science_rounded
                          : Icons.local_pharmacy_rounded,
                      size: 14,
                      color: active
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      m == MapMode.labs ? 'Labs' : 'Pharmacies',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: active
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Lab list card ─────────────────────────────────────────────────────────────

class _LabListCard extends ConsumerWidget {
  const _LabListCard({
    required this.lab,
    required this.isSelected,
    this.badge,
  });
  final LabLocation lab;
  final bool isSelected;
  final String? badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Row(
                    children: [
                      Flexible(
                          child: Text(lab.name,
                              style: AppTextStyles.labelLarge)),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        _Badge(label: badge!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(lab.address,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
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
                      const SizedBox(width: 8),
                      const Icon(Icons.near_me_rounded,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        '${lab.distanceKm} km',
                        style: AppTextStyles.bodySmall
                            .copyWith(fontSize: 11),
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
            const SizedBox(width: AppSpacing.s8),
            CuroButton(
              label: 'Book',
              width: 72,
              onPressed: () {
                ref.read(recentlyViewedLabsProvider.notifier).add(lab.id);
                context.push(AppRoutes.labDetail, extra: lab);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pharmacy card ─────────────────────────────────────────────────────────────

class _PharmacyCard extends StatelessWidget {
  const _PharmacyCard({
    required this.pharmacy,
    required this.isSelected,
    this.badge,
  });
  final PharmacyLocation pharmacy;
  final bool isSelected;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF22C55E).withValues(alpha: 0.05)
            : Colors.transparent,
        border: isSelected
            ? const Border(
                left: BorderSide(color: Color(0xFF22C55E), width: 3))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: pharmacy.avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_pharmacy_rounded,
                      color: Colors.white, size: 24),
                ),
                if (pharmacy.is24Hours)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('24H',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                          child: Text(pharmacy.name,
                              style: AppTextStyles.labelLarge)),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        _Badge(
                            label: badge!,
                            color: const Color(0xFF22C55E)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(pharmacy.address,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        '${pharmacy.rating} (${pharmacy.reviewCount})',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary, fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.near_me_rounded,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        '${pharmacy.distanceKm} km',
                        style: AppTextStyles.bodySmall
                            .copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          pharmacy.openingHours,
                          style: AppTextStyles.bodySmall
                              .copyWith(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            GestureDetector(
              onTap: () async {
                final uri = Uri(scheme: 'tel', path: pharmacy.phone);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  await Clipboard.setData(
                      ClipboardData(text: pharmacy.phone));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied: ${pharmacy.phone}')),
                    );
                  }
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FDF2),
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  border: Border.all(color: const Color(0xFF22C55E)),
                ),
                child: const Icon(Icons.call_rounded,
                    size: 18, color: Color(0xFF22C55E)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared badge widget ────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── OSM real-world marker (small, outlined) ────────────────────────────────────

class _OsmMarker extends StatelessWidget {
  const _OsmMarker({required this.place, required this.onTap});
  final OsmPlace place;
  final VoidCallback onTap;

  static Color _color(OsmAmenity a) => switch (a) {
        OsmAmenity.hospital => const Color(0xFFEF4444),
        OsmAmenity.pharmacy => const Color(0xFF22C55E),
        OsmAmenity.clinic || OsmAmenity.doctors => const Color(0xFF3B82F6),
        OsmAmenity.laboratory => const Color(0xFF8B5CF6),
        _ => const Color(0xFF6B7280),
      };

  static IconData _icon(OsmAmenity a) => switch (a) {
        OsmAmenity.hospital => Icons.local_hospital_rounded,
        OsmAmenity.pharmacy => Icons.local_pharmacy_rounded,
        OsmAmenity.clinic || OsmAmenity.doctors => Icons.medical_services_rounded,
        OsmAmenity.laboratory => Icons.science_rounded,
        _ => Icons.health_and_safety_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(place.amenity);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Icon(_icon(place.amenity), size: 15, color: color),
      ),
    );
  }
}

// ── OSM place detail modal sheet ──────────────────────────────────────────────

class _OsmPlaceSheet extends StatelessWidget {
  const _OsmPlaceSheet({
    required this.place,
    this.matchedLab,
    this.matchedPharmacy,
  });

  final OsmPlace place;
  final LabLocation? matchedLab;
  final PharmacyLocation? matchedPharmacy;

  static Color _typeColor(OsmAmenity a) => switch (a) {
        OsmAmenity.hospital => const Color(0xFFEF4444),
        OsmAmenity.pharmacy => const Color(0xFF22C55E),
        OsmAmenity.clinic || OsmAmenity.doctors => const Color(0xFF3B82F6),
        OsmAmenity.laboratory => const Color(0xFF8B5CF6),
        _ => AppColors.primary,
      };

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Clipboard.setData(ClipboardData(text: phone));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copied: $phone')),
        );
      }
    }
  }

  Future<void> _openWebsite(String url) async {
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(place.amenity);
    final hasPhone = place.phone.isNotEmpty;
    final hasHours = place.openingHours.isNotEmpty;
    final hasWeb = place.website.isNotEmpty;
    final inCuro = matchedLab != null || matchedPharmacy != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_rounded, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        'OpenStreetMap · ${place.amenityLabel}',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: color, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Name
                Text(place.name,
                    style: AppTextStyles.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),

                if (hasHours) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(place.openingHours,
                          style: AppTextStyles.bodySmall),
                    ),
                  ]),
                ],

                if (hasPhone) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.phone_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Text(place.phone, style: AppTextStyles.bodySmall),
                  ]),
                ],

                const SizedBox(height: 20),

                // CURO booking match
                if (inCuro) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This location is bookable via CURO',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: CuroButton(
                      label: 'Book via CURO',
                      onPressed: () {
                        Navigator.pop(context);
                        if (matchedLab != null) {
                          context.push(AppRoutes.labDetail,
                              extra: matchedLab);
                        } else if (matchedPharmacy != null) {
                          // Navigate to lab detail with nearest lab as fallback
                          // (pharmacy booking not yet implemented separately)
                        }
                      },
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 18, color: Colors.amber),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Not yet in CURO. Call them directly or search nearby.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Action row
                Row(
                  children: [
                    if (hasPhone)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _call(context, place.phone),
                          icon: const Icon(Icons.call_rounded, size: 16),
                          label: const Text('Call'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF22C55E),
                            side: const BorderSide(color: Color(0xFF22C55E)),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.r12)),
                          ),
                        ),
                      ),
                    if (hasPhone && hasWeb) const SizedBox(width: 10),
                    if (hasWeb)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openWebsite(place.website),
                          icon: const Icon(Icons.language_rounded, size: 16),
                          label: const Text('Website'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.r12)),
                          ),
                        ),
                      ),
                    if (!hasPhone && !hasWeb)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Dismiss'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.r12)),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
