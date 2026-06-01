import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/medicine_model.dart';
import 'app_providers.dart';

// ── Search state ──────────────────────────────────────────────────────────────

class MedicineSearchState {
  const MedicineSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });
  final String query;
  final List<MedicineModel> results;
  final bool isLoading;
  final String? error;
}

class MedicineSearchNotifier extends Notifier<MedicineSearchState> {
  @override
  MedicineSearchState build() => const MedicineSearchState();

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const MedicineSearchState();
      return;
    }
    state = MedicineSearchState(query: query, isLoading: true);
    try {
      final results = await ref
          .read(medicineRepositoryProvider)
          .searchMedicines(query);
      state = MedicineSearchState(query: query, results: results);
    } catch (e) {
      state = MedicineSearchState(query: query, error: e.toString());
    }
  }

  /// Called after prescription scan — fetch medicines by name list.
  Future<void> fetchByNames(List<String> names) async {
    state = const MedicineSearchState(isLoading: true);
    try {
      final results = await ref
          .read(medicineRepositoryProvider)
          .getMedicinesByNames(names);
      state = MedicineSearchState(results: results);
    } catch (e) {
      state = MedicineSearchState(error: e.toString());
    }
  }
}

final medicineSearchProvider =
    NotifierProvider<MedicineSearchNotifier, MedicineSearchState>(
      MedicineSearchNotifier.new,
    );
