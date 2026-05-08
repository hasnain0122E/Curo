import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};
  String? _selectedLabId;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  static const _initialCamera = CameraPosition(
    target: LatLng(24.8607, 67.0011),
    zoom: 13.5,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildMarkers());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _buildMarkers() async {
    final labs = ref.read(allLabsProvider);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final newMarkers = <MarkerId, Marker>{};

    for (final lab in labs) {
      final icon = await _createPriceMarker(lab.startingPriceRs, ratio);
      final id = MarkerId(lab.id);
      newMarkers[id] = Marker(
        markerId: id,
        position: LatLng(lab.lat, lab.lng),
        icon: icon,
        onTap: () {
          setState(() => _selectedLabId = lab.id);
          _sheetController.animateTo(
            0.48,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
          );
        },
      );
    }

    if (mounted) setState(() => _markers.addAll(newMarkers));
  }

  Future<BitmapDescriptor> _createPriceMarker(
      int priceRs, double ratio) async {
    const double w = 84;
    const double bh = 34; // bubble height
    const double ph = 10; // pointer height
    const double r = 17.0; // corner radius
    final double totalH = bh + ph;
    final int pw = (w * ratio).toInt();
    final int pTotalH = (totalH * ratio).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, pw.toDouble(), pTotalH.toDouble()),
    );
    canvas.scale(ratio);

    final paint = Paint()..color = AppColors.primary;

    // Bubble
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, bh), Radius.circular(r)),
      paint,
    );

    // Pointer triangle
    canvas.drawPath(
      Path()
        ..moveTo(w / 2 - 7, bh)
        ..lineTo(w / 2 + 7, bh)
        ..lineTo(w / 2, totalH)
        ..close(),
      paint,
    );

    // Price text
    final tp = TextPainter(
      text: TextSpan(
        text: '₨$priceRs',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w);
    tp.paint(canvas, Offset((w - tp.width) / 2, (bh - tp.height) / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(pw, pTotalH);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      imagePixelRatio: ratio,
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
    final labs = ref.watch(filteredLabsProvider);

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen map ──────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: _initialCamera,
            markers: Set<Marker>.of(_markers.values),
            style: _kMapStyle,
            onMapCreated: (ctrl) => _mapController = ctrl,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            onTap: (_) => setState(() => _selectedLabId = null),
          ),

          // ── Top overlay: search bar + filter pills ───────────────────────
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16, AppSpacing.s12,
                      AppSpacing.s16, 0),
                  child: _SearchBar(),
                ),
                const SizedBox(height: AppSpacing.s8),
                _FilterRow(),
              ],
            ),
          ),

          // ── My-location FAB ──────────────────────────────────────────────
          Positioned(
            right: AppSpacing.s16,
            bottom: 300,
            child: GestureDetector(
              onTap: () => _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(_initialCamera),
              ),
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

          // ── Draggable bottom sheet ───────────────────────────────────────
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
      bottomNavigationBar: CuroBottomNavBar(
        currentIndex: 1,
        onTap: _onNavTap,
      ),
    );
  }
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
          Container(
            width: 1,
            height: 24,
            color: AppColors.border,
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
        itemBuilder: (_, i) {
          final (filter, label) = filters[i];
          final active = current == filter;
          return GestureDetector(
            onTap: () => ref.read(labFilterProvider.notifier).set(filter),
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
                  color: active ? AppColors.primary : AppColors.textSecondary,
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
    // Selected lab floats to top
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
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          // Drag handle + header
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
                  child: Text(
                    '${labs.length} labs found nearby',
                    style: AppTextStyles.h3,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                const Divider(height: 1, color: AppColors.border),
              ],
            ),
          ),

          // Lab cards
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _LabListCard(
                lab: sorted[i],
                isSelected: sorted[i].id == selectedLabId,
              ),
              childCount: sorted.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s24)),
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
            // Avatar
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

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lab.name, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    lab.address,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        '${lab.rating} (${lab.reviewCount})',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Starts ₨ ${lab.startingPriceRs}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Book button
            CuroButton(
              label: 'Book',
              width: 72,
              onPressed: () => context.push(AppRoutes.labDetail, extra: lab),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Minimal map style JSON ────────────────────────────────────────────────────

const _kMapStyle = '''[
  {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#e8edf2"}]},
  {"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#8a9bb0"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#f0f4f8"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#dbe4ed"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#6b7a8d"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#9baab8"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f5f9ff"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#dce5ee"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#4a6080"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c8e6f5"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#8aabb8"}]}
]''';
