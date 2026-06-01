import 'package:cloud_firestore/cloud_firestore.dart';

class LabModel {
  const LabModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.reviewCount,
    required this.startingPriceRs,
    required this.openingHours,
    this.city = '',
    this.area = '',
    this.phone = '',
    this.website = '',
    this.is24Hours = false,
    this.tests = const [],
  });

  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double rating;
  final int reviewCount;
  final int startingPriceRs;
  final String openingHours;
  final String city;
  final String area;
  final String phone;
  final String website;
  final bool is24Hours;
  final List<String> tests;

  factory LabModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return LabModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      startingPriceRs: (data['startingPriceRs'] as num?)?.toInt() ?? 0,
      openingHours: data['openingHours'] as String? ?? '',
      city: data['city'] as String? ?? '',
      area: data['area'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      website: data['website'] as String? ?? '',
      is24Hours: data['is24Hours'] as bool? ?? false,
      tests: List<String>.from(data['tests'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'address': address,
    'area': area,
    'city': city,
    'lat': lat,
    'lng': lng,
    'rating': rating,
    'reviewCount': reviewCount,
    'startingPriceRs': startingPriceRs,
    'openingHours': openingHours,
    'phone': phone,
    'website': website,
    'is24Hours': is24Hours,
    'tests': tests,
  };
}
