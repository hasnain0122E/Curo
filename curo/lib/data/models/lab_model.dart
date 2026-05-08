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
      reviewCount: data['reviewCount'] as int? ?? 0,
      startingPriceRs: data['startingPriceRs'] as int? ?? 0,
      openingHours: data['openingHours'] as String? ?? '',
      tests: List<String>.from(data['tests'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'rating': rating,
        'reviewCount': reviewCount,
        'startingPriceRs': startingPriceRs,
        'openingHours': openingHours,
        'tests': tests,
      };
}
