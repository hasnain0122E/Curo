import 'dart:convert';
import 'package:http/http.dart' as http;

enum OsmAmenity { pharmacy, hospital, clinic, laboratory, doctors, other }

class OsmPlace {
  const OsmPlace({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.amenity,
    this.phone = '',
    this.openingHours = '',
    this.website = '',
    this.city = '',
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
  final OsmAmenity amenity;
  final String phone;
  final String openingHours;
  final String website;
  final String city;

  String get amenityLabel => switch (amenity) {
        OsmAmenity.pharmacy => 'Pharmacy',
        OsmAmenity.hospital => 'Hospital',
        OsmAmenity.clinic => 'Clinic',
        OsmAmenity.laboratory => 'Laboratory',
        OsmAmenity.doctors => 'Doctor / GP',
        OsmAmenity.other => 'Healthcare',
      };
}

/// Fetches nearby healthcare places from the OpenStreetMap Overpass API.
class OverpassService {
  static const _url = 'https://overpass-api.de/api/interpreter';

  static Future<List<OsmPlace>> fetchNearby({
    required double lat,
    required double lng,
    double radiusMeters = 4000,
  }) async {
    // Overpass QL: nodes and ways with healthcare amenity tags near [lat,lng]
    final query = '''
[out:json][timeout:25];
(
  node["amenity"~"pharmacy|hospital|clinic|laboratory|doctors"](around:$radiusMeters,$lat,$lng);
  way["amenity"~"pharmacy|hospital|clinic|laboratory|doctors"](around:$radiusMeters,$lat,$lng);
);
out center;
''';

    try {
      final response = await http
          .post(
            Uri.parse(_url),
            body: query,
            headers: {'Content-Type': 'text/plain; charset=utf-8'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = decoded['elements'] as List<dynamic>? ?? [];

      final places = <OsmPlace>[];
      for (final el in elements) {
        final map = el as Map<String, dynamic>;
        final tags = (map['tags'] as Map<String, dynamic>?) ?? {};

        // Prefer English name then any name
        final name = (tags['name:en'] as String? ??
                tags['name'] as String? ??
                '')
            .trim();
        if (name.isEmpty) continue;

        // Coordinates: node → direct, way → center object
        double? pLat, pLng;
        if (map['type'] == 'node') {
          pLat = (map['lat'] as num?)?.toDouble();
          pLng = (map['lon'] as num?)?.toDouble();
        } else {
          final center = map['center'] as Map<String, dynamic>?;
          pLat = (center?['lat'] as num?)?.toDouble();
          pLng = (center?['lon'] as num?)?.toDouble();
        }
        if (pLat == null || pLng == null) continue;

        final amenityStr = tags['amenity'] as String? ?? '';
        final amenity = switch (amenityStr) {
          'pharmacy' => OsmAmenity.pharmacy,
          'hospital' => OsmAmenity.hospital,
          'clinic' => OsmAmenity.clinic,
          'laboratory' => OsmAmenity.laboratory,
          'doctors' => OsmAmenity.doctors,
          _ => OsmAmenity.other,
        };

        final phone = (tags['phone'] ??
                tags['contact:phone'] ??
                tags['contact:mobile'] ??
                '') as String;

        places.add(OsmPlace(
          id: '${map['type']}_${map['id']}',
          name: name,
          lat: pLat,
          lng: pLng,
          amenity: amenity,
          phone: phone.trim(),
          openingHours: (tags['opening_hours'] as String? ?? '').trim(),
          website: (tags['website'] ?? tags['contact:website'] ?? '') as String,
          city: (tags['addr:city'] as String? ?? '').trim(),
        ));

        if (places.length >= 60) break; // cap for performance
      }

      return places;
    } catch (_) {
      // Overpass can be unavailable — fail silently, map still shows Firebase data
      return [];
    }
  }
}
