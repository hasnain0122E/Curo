import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pharmacy_model.dart';

class PharmacyRepository {
  PharmacyRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<PharmacyModel> get _col =>
      _firestore.collection('pharmacies').withConverter<PharmacyModel>(
            fromFirestore: (snap, _) => PharmacyModel.fromFirestore(snap),
            toFirestore: (model, _) => model.toFirestore(),
          );

  Stream<List<PharmacyModel>> watchPharmacies() => _col
      .orderBy('rating', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());
}
