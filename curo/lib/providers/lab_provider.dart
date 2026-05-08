import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/lab_model.dart';
import 'app_providers.dart';

/// Stream of all labs ordered by rating.
final labsStreamProvider = StreamProvider<List<LabModel>>((ref) {
  return ref.watch(labRepositoryProvider).watchLabs();
});

/// One-shot fetch (used on pages that don't need live updates).
final nearbyLabsFutureProvider =
    FutureProvider<List<LabModel>>((ref) async {
  return ref.watch(labRepositoryProvider).getLabsNearby();
});

/// Single lab by id.
final labByIdProvider =
    FutureProvider.family<LabModel?, String>((ref, labId) async {
  return ref.watch(labRepositoryProvider).getLabById(labId);
});
