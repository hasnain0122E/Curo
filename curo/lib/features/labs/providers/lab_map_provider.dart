import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/lab_model.dart';
import '../../../data/models/pharmacy_model.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/overpass_service.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/lab_provider.dart';
import '../../../providers/pharmacy_provider.dart';

// ── Map mode (Labs / Pharmacies) ──────────────────────────────────────────────

enum MapMode { labs, pharmacies }

final mapModeProvider =
    NotifierProvider<_MapModeNotifier, MapMode>(_MapModeNotifier.new);

class _MapModeNotifier extends Notifier<MapMode> {
  @override
  MapMode build() => MapMode.labs;
  void set(MapMode m) => state = m;
}

// ── Search query (shared across modes) ────────────────────────────────────────

final labSearchProvider =
    NotifierProvider<_SearchNotifier, String>(_SearchNotifier.new);

class _SearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String q) => state = q;
}

// ── Avatar colors (deterministic by id) ───────────────────────────────────────

const _avatarColors = [
  Color(0xFF1A5276),
  Color(0xFF154360),
  Color(0xFF0B5345),
  Color(0xFF4A235A),
  Color(0xFF1B4F72),
  Color(0xFF6E2F0A),
];

Color _avatarColor(String id) =>
    _avatarColors[id.hashCode.abs() % _avatarColors.length];

// Fallback location when GPS permission is denied (Karachi city centre)
const _fallbackLat = 24.8607;
const _fallbackLng = 67.0114;

// Discovery limits: max results for Nearest/Cheapest/TopRated filters
const _kMaxFiltered = 5;
// Radius (km) used when real GPS is available for the "Nearest" filter
const _kNearbyKm = 10.0;

// ── Lab display model ─────────────────────────────────────────────────────────

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
    required this.city,
    this.area = '',
    this.phone = '',
    this.website = '',
    this.is24Hours = false,
    this.openingHours = '',
    this.tests = const [],
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
  final String city;
  final String area;
  final String phone;
  final String website;
  final bool is24Hours;
  final String openingHours;
  final List<String> tests;
}

enum LabFilter { all, nearest, cheapest, highestRated }

final labFilterProvider =
    NotifierProvider<_LabFilterNotifier, LabFilter>(_LabFilterNotifier.new);

class _LabFilterNotifier extends Notifier<LabFilter> {
  @override
  LabFilter build() => LabFilter.cheapest;
  void set(LabFilter f) => state = f;
}

// Holds test names extracted from a lab prescription scan; empty = no filter.
class _LabTestNamesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];
  void set(List<String> tests) => state = tests;
}

final labTestNamesFilterProvider =
    NotifierProvider<_LabTestNamesNotifier, List<String>>(
        _LabTestNamesNotifier.new);

LabLocation _toLabLocation(LabModel lab, double userLat, double userLng) {
  final dist = LocationService.distanceKm(userLat, userLng, lab.lat, lab.lng);
  return LabLocation(
    id:              lab.id,
    name:            lab.name,
    address:         lab.address,
    lat:             lab.lat,
    lng:             lab.lng,
    distanceKm:      double.parse(dist.toStringAsFixed(1)),
    rating:          lab.rating,
    reviewCount:     '${lab.reviewCount}+',
    startingPriceRs: lab.startingPriceRs,
    avatarColor:     _avatarColor(lab.id),
    city:            lab.city,
    area:            lab.area,
    phone:           lab.phone,
    website:         lab.website,
    is24Hours:       lab.is24Hours,
    openingHours:    lab.openingHours,
    tests:           lab.tests,
  );
}

final allLabsProvider = Provider<List<LabLocation>>((ref) {
  final models = ref.watch(labsStreamProvider).asData?.value ?? [];
  final pos = ref.watch(userLocationProvider).asData?.value;
  final lat = pos?.latitude ?? _fallbackLat;
  final lng = pos?.longitude ?? _fallbackLng;
  return models.map((lab) => _toLabLocation(lab, lat, lng)).toList();
});

final filteredLabsProvider = Provider<List<LabLocation>>((ref) {
  final filter = ref.watch(labFilterProvider);
  final query = ref.watch(labSearchProvider).toLowerCase().trim();
  final labs = ref.watch(allLabsProvider);
  final hasGps = ref.watch(userLocationProvider).asData?.value != null;
  final testNames = ref.watch(labTestNamesFilterProvider);

  var searched = query.isEmpty
      ? labs
      : labs
          .where((l) =>
              l.name.toLowerCase().contains(query) ||
              l.address.toLowerCase().contains(query) ||
              l.city.toLowerCase().contains(query) ||
              l.area.toLowerCase().contains(query))
          .toList();

  // When coming from lab test scan, narrow to labs that offer those tests.
  if (testNames.isNotEmpty) {
    final lowerTests = testNames.map((t) => t.toLowerCase()).toSet();
    final matched = searched.where((lab) {
      final labTests = lab.tests.map((t) => t.toLowerCase()).toList();
      return lowerTests.any(
          (test) => labTests.any((lt) => lt.contains(test) || test.contains(lt)));
    }).toList();
    if (matched.isNotEmpty) searched = matched;
  }

  switch (filter) {
    case LabFilter.all:
      return searched;
    case LabFilter.nearest:
      final sorted = [...searched]
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      if (hasGps && query.isEmpty) {
        final nearby =
            sorted.where((l) => l.distanceKm <= _kNearbyKm).take(_kMaxFiltered).toList();
        return nearby.isEmpty ? sorted.take(_kMaxFiltered).toList() : nearby;
      }
      return sorted.take(_kMaxFiltered).toList();
    case LabFilter.cheapest:
      return ([...searched]
            ..sort((a, b) => a.startingPriceRs.compareTo(b.startingPriceRs)))
          .take(_kMaxFiltered)
          .toList();
    case LabFilter.highestRated:
      return ([...searched]..sort((a, b) => b.rating.compareTo(a.rating)))
          .take(_kMaxFiltered)
          .toList();
  }
});

// ── Pharmacy display model ────────────────────────────────────────────────────

class PharmacyLocation {
  const PharmacyLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.openingHours,
    required this.phone,
    required this.is24Hours,
    required this.avatarColor,
    required this.city,
    this.area = '',
    this.website = '',
    this.services = const [],
  });

  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double distanceKm;
  final double rating;
  final int reviewCount;
  final String openingHours;
  final String phone;
  final bool is24Hours;
  final Color avatarColor;
  final String city;
  final String area;
  final String website;
  final List<String> services;
}

enum PharmacyFilter { all, nearest, open24h, highestRated }

final pharmacyFilterProvider =
    NotifierProvider<_PharmacyFilterNotifier, PharmacyFilter>(
        _PharmacyFilterNotifier.new);

class _PharmacyFilterNotifier extends Notifier<PharmacyFilter> {
  @override
  PharmacyFilter build() => PharmacyFilter.all;
  void set(PharmacyFilter f) => state = f;
}

PharmacyLocation _toPharmacyLocation(
    PharmacyModel p, double userLat, double userLng) {
  final dist = LocationService.distanceKm(userLat, userLng, p.lat, p.lng);
  return PharmacyLocation(
    id:           p.id,
    name:         p.name,
    address:      p.address,
    lat:          p.lat,
    lng:          p.lng,
    distanceKm:   double.parse(dist.toStringAsFixed(1)),
    rating:       p.rating,
    reviewCount:  p.reviewCount,
    openingHours: p.openingHours,
    phone:        p.phone,
    is24Hours:    p.is24Hours,
    avatarColor:  _avatarColor(p.id),
    city:         p.city,
    area:         p.area,
    website:      p.website,
    services:     p.services,
  );
}

final allPharmaciesProvider = Provider<List<PharmacyLocation>>((ref) {
  final models = ref.watch(pharmaciesStreamProvider).asData?.value ?? [];
  final pos = ref.watch(userLocationProvider).asData?.value;
  final lat = pos?.latitude ?? _fallbackLat;
  final lng = pos?.longitude ?? _fallbackLng;
  return models.map((p) => _toPharmacyLocation(p, lat, lng)).toList();
});

final filteredPharmaciesProvider = Provider<List<PharmacyLocation>>((ref) {
  final filter = ref.watch(pharmacyFilterProvider);
  final query = ref.watch(labSearchProvider).toLowerCase().trim();
  final pharmacies = ref.watch(allPharmaciesProvider);
  final hasGps = ref.watch(userLocationProvider).asData?.value != null;

  final searched = query.isEmpty
      ? pharmacies
      : pharmacies
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              p.address.toLowerCase().contains(query) ||
              p.city.toLowerCase().contains(query) ||
              p.area.toLowerCase().contains(query))
          .toList();

  switch (filter) {
    case PharmacyFilter.all:
      return searched;
    case PharmacyFilter.nearest:
      final sorted = [...searched]
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      if (hasGps && query.isEmpty) {
        final nearby =
            sorted.where((p) => p.distanceKm <= _kNearbyKm).take(_kMaxFiltered).toList();
        return nearby.isEmpty ? sorted.take(_kMaxFiltered).toList() : nearby;
      }
      return sorted.take(_kMaxFiltered).toList();
    case PharmacyFilter.open24h:
      return (searched.where((p) => p.is24Hours).toList()
            ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm)))
          .take(_kMaxFiltered)
          .toList();
    case PharmacyFilter.highestRated:
      return ([...searched]..sort((a, b) => b.rating.compareTo(a.rating)))
          .take(_kMaxFiltered)
          .toList();
  }
});

// ── Real-time OSM places (Overpass API) ───────────────────────────────────────
// Fetches nearby healthcare POIs from OpenStreetMap when user location is known.
// Fails silently — Firebase markers always take precedence.
final osmPlacesProvider =
    FutureProvider.autoDispose<List<OsmPlace>>((ref) async {
  final pos = await ref.watch(userLocationProvider.future);
  if (pos == null) return [];
  return OverpassService.fetchNearby(
    lat: pos.latitude,
    lng: pos.longitude,
    radiusMeters: 4000,
  );
});
