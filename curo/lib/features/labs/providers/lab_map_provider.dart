import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/lab_model.dart';
import '../../../providers/lab_provider.dart';

enum LabFilter { all, nearest, cheapest, highestRated }

class LabLocation {
  const LabLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.startingPriceRs,
    required this.avatarColor,
  });

  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double distanceKm;
  final double rating;
  final String reviewCount;
  final int startingPriceRs;
  final Color avatarColor;
}

// ── Firebase mapping ───────────────────────────────────────────────────────────

const _avatarColors = [
  Color(0xFF1A5276),
  Color(0xFF154360),
  Color(0xFF0B5345),
  Color(0xFF4A235A),
  Color(0xFF1B4F72),
];

const _distancesKm = [0.8, 1.5, 2.1, 2.8, 3.4];

LabLocation _toLabLocation(LabModel lab, int index) => LabLocation(
      id: lab.id,
      name: lab.name,
      address: lab.address,
      lat: lab.lat,
      lng: lab.lng,
      distanceKm: _distancesKm[index % _distancesKm.length],
      rating: lab.rating,
      reviewCount: '${lab.reviewCount}+',
      startingPriceRs: lab.startingPriceRs,
      avatarColor: _avatarColors[index % _avatarColors.length],
    );

// ── Providers ──────────────────────────────────────────────────────────────────

final labFilterProvider =
    NotifierProvider<_FilterNotifier, LabFilter>(_FilterNotifier.new);

class _FilterNotifier extends Notifier<LabFilter> {
  @override
  LabFilter build() => LabFilter.all;
  void set(LabFilter f) => state = f;
}

final allLabsProvider = Provider<List<LabLocation>>((ref) {
  final asyncLabs = ref.watch(labsStreamProvider);
  final models = asyncLabs.asData?.value ?? [];
  return [for (int i = 0; i < models.length; i++) _toLabLocation(models[i], i)];
});

final filteredLabsProvider = Provider<List<LabLocation>>((ref) {
  final filter = ref.watch(labFilterProvider);
  final labs = ref.watch(allLabsProvider);
  return switch (filter) {
    LabFilter.all => labs,
    LabFilter.nearest =>
      [...labs]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm)),
    LabFilter.cheapest =>
      [...labs]..sort((a, b) => a.startingPriceRs.compareTo(b.startingPriceRs)),
    LabFilter.highestRated =>
      [...labs]..sort((a, b) => b.rating.compareTo(a.rating)),
  };
});
