import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/pharmacy_model.dart';
import 'app_providers.dart';

final pharmaciesStreamProvider = StreamProvider<List<PharmacyModel>>((ref) {
  return ref.watch(pharmacyRepositoryProvider).watchPharmacies();
});
