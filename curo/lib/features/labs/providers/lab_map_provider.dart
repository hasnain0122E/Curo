import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// ── Mock data ──────────────────────────────────────────────────────────────────

const _mockLabs = [
  LabLocation(
    id: '1',
    name: 'Apollo Diagnostics',
    address: '0.8 km · Jubilee Hills',
    lat: 24.8607,
    lng: 67.0011,
    distanceKm: 0.8,
    rating: 4.8,
    reviewCount: '2.4k+',
    startingPriceRs: 450,
    avatarColor: Color(0xFF1A5276),
  ),
  LabLocation(
    id: '2',
    name: 'Metropolis Lab',
    address: '1.5 km · Banara Hills',
    lat: 24.8660,
    lng: 67.0105,
    distanceKm: 1.5,
    rating: 4.5,
    reviewCount: '1.8k+',
    startingPriceRs: 890,
    avatarColor: Color(0xFF154360),
  ),
  LabLocation(
    id: '3',
    name: 'Chughtai Lab',
    address: '2.1 km · Clifton',
    lat: 24.8540,
    lng: 66.9895,
    distanceKm: 2.1,
    rating: 4.7,
    reviewCount: '3.1k+',
    startingPriceRs: 1200,
    avatarColor: Color(0xFF0B5345),
  ),
  LabLocation(
    id: '4',
    name: 'Dr. Essa Laboratory',
    address: '2.8 km · Gulshan-e-Iqbal',
    lat: 24.8710,
    lng: 67.0185,
    distanceKm: 2.8,
    rating: 4.6,
    reviewCount: '980+',
    startingPriceRs: 350,
    avatarColor: Color(0xFF4A235A),
  ),
  LabLocation(
    id: '5',
    name: 'Agha Khan Lab',
    address: '3.4 km · Saddar',
    lat: 24.8475,
    lng: 67.0255,
    distanceKm: 3.4,
    rating: 4.9,
    reviewCount: '5.2k+',
    startingPriceRs: 750,
    avatarColor: Color(0xFF1B4F72),
  ),
];

// ── Providers ──────────────────────────────────────────────────────────────────

final labFilterProvider =
    NotifierProvider<_FilterNotifier, LabFilter>(_FilterNotifier.new);

class _FilterNotifier extends Notifier<LabFilter> {
  @override
  LabFilter build() => LabFilter.all;
  void set(LabFilter f) => state = f;
}

final allLabsProvider = Provider<List<LabLocation>>((_) => _mockLabs);

final filteredLabsProvider = Provider<List<LabLocation>>((ref) {
  final filter = ref.watch(labFilterProvider);
  final labs = ref.watch(allLabsProvider);
  return switch (filter) {
    LabFilter.all => labs,
    LabFilter.nearest => [...labs]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm)),
    LabFilter.cheapest => [...labs]..sort((a, b) => a.startingPriceRs.compareTo(b.startingPriceRs)),
    LabFilter.highestRated => [...labs]..sort((a, b) => b.rating.compareTo(a.rating)),
  };
});
