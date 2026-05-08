import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineModel {
  const MedicineModel({
    required this.id,
    required this.name,
    required this.nameLower,
    required this.manufacturer,
    required this.packSize,
    required this.priceBeforeRs,
    required this.priceAfterRs,
    required this.discountPercent,
    required this.available,
  });

  final String id;
  final String name;
  final String nameLower;
  final String manufacturer;
  final String packSize;
  final int priceBeforeRs;
  final int priceAfterRs;
  final int discountPercent;
  final bool available;

  bool get hasDiscount => discountPercent > 0 && priceAfterRs < priceBeforeRs;

  factory MedicineModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final priceBefore = (d['priceBeforeRs'] as num?)?.toInt() ?? 0;
    final priceAfter  = (d['priceAfterRs']  as num?)?.toInt() ?? priceBefore;
    return MedicineModel(
      id:              doc.id,
      name:            d['name']            as String? ?? '',
      nameLower:       d['nameLower']       as String? ?? '',
      manufacturer:    d['manufacturer']    as String? ?? '',
      packSize:        d['packSize']        as String? ?? '',
      priceBeforeRs:   priceBefore,
      priceAfterRs:    priceAfter,
      discountPercent: (d['discountPercent'] as num?)?.toInt() ?? 0,
      available:       d['available']       as bool?   ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name':            name,
        'nameLower':       nameLower,
        'manufacturer':    manufacturer,
        'packSize':        packSize,
        'priceBeforeRs':   priceBeforeRs,
        'priceAfterRs':    priceAfterRs,
        'discountPercent': discountPercent,
        'available':       available,
      };
}
