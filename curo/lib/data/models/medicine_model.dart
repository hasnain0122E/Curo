import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineModel {
  const MedicineModel({
    required this.id,
    required this.name,
    required this.nameLower,
    required this.genericName,
    required this.manufacturer,
    required this.category,
    required this.description,
    required this.strength,
    required this.packSize,
    required this.available,
    required this.inStock,
    required this.prescriptionRequired,
    required this.priceBeforeRs,
    required this.priceAfterRs,
    required this.discountPercent,
    required this.pharmacies,
    required this.usage,
    this.city = 'Karachi',
    this.country = 'Pakistan',
  });

  final String id;
  final String name;
  final String nameLower;
  final String genericName;
  final String manufacturer;
  final String category;
  final String description;
  final String strength;
  final String packSize;
  final bool available;
  final bool inStock;
  final bool prescriptionRequired;
  final int priceBeforeRs;
  final int priceAfterRs;
  final int discountPercent;
  final List<String> pharmacies;
  final List<String> usage;
  final String city;
  final String country;

  bool get hasDiscount => discountPercent > 0 && priceAfterRs < priceBeforeRs;
  String get displayForm =>
      [strength, packSize].where((s) => s.isNotEmpty).join(' · ');

  factory MedicineModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    final priceBefore = (d['priceBeforeRs'] as num?)?.toInt() ?? 0;
    final priceAfter = (d['priceAfterRs'] as num?)?.toInt() ?? priceBefore;
    return MedicineModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      nameLower: d['nameLower'] as String? ?? '',
      genericName: d['genericName'] as String? ?? '',
      manufacturer: d['manufacturer'] as String? ?? '',
      category: d['category'] as String? ?? 'tablet',
      description: d['description'] as String? ?? '',
      strength: d['strength'] as String? ?? '',
      packSize: d['packSize'] as String? ?? '',
      available: d['available'] as bool? ?? true,
      inStock: d['inStock'] as bool? ?? true,
      prescriptionRequired: d['prescriptionRequired'] as bool? ?? false,
      priceBeforeRs: priceBefore,
      priceAfterRs: priceAfter,
      discountPercent: (d['discountPercent'] as num?)?.toInt() ?? 0,
      pharmacies: List<String>.from(d['pharmacies'] as List? ?? []),
      usage: List<String>.from(d['usage'] as List? ?? []),
      city: d['city'] as String? ?? 'Karachi',
      country: d['country'] as String? ?? 'Pakistan',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'nameLower': nameLower,
    'genericName': genericName,
    'genericNameLower': genericName.toLowerCase(),
    'manufacturer': manufacturer,
    'category': category,
    'description': description,
    'strength': strength,
    'packSize': packSize,
    'available': available,
    'inStock': inStock,
    'prescriptionRequired': prescriptionRequired,
    'priceBeforeRs': priceBeforeRs,
    'priceAfterRs': priceAfterRs,
    'discountPercent': discountPercent,
    'pharmacies': pharmacies,
    'usage': usage,
    'city': city,
    'country': country,
  };
}
