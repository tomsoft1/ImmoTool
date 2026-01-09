import 'package:json_annotation/json_annotation.dart';

part 'dpe_data.g.dart';

@JsonSerializable()
class DpeData {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'adresse_complete', defaultValue: 'Address unknown')
  final String address;

  @JsonKey(name: 'geo_adresse', defaultValue: '')
  final String geoAddress;

  @JsonKey(name: 'date_etablissement_dpe', defaultValue: '')
  final String dpeDate;

  @JsonKey(name: 'latitude', defaultValue: 48.8566)
  final double latitude;

  @JsonKey(name: 'longitude', defaultValue: 2.3522)
  final double longitude;

  @JsonKey(name: 'classe_consommation_energie', defaultValue: 'N/A')
  final String energyGrade;

  @JsonKey(name: 'conso_energie', defaultValue: 0)
  final int energyValue;

  @JsonKey(name: 'classe_estimation_ges', defaultValue: 'N/A')
  final String gesGrade;

//  @JsonKey(name: 'estimation_ges', defaultValue: 0)
//  final int gesValue;

  @JsonKey(name: 'surface_thermique_lot', defaultValue: 0)
  final double surface;

  DpeData({
    required this.id,
    required this.address,
    required this.geoAddress,
    required this.dpeDate,
    required this.latitude,
    required this.longitude,
    required this.energyGrade,
    required this.energyValue,
    required this.gesGrade,
//    required this.gesValue,
    required this.surface,
  });

  String get formattedDate {
    if (dpeDate.isEmpty) return 'Date inconnue';
    try {
      final date = DateTime.parse(dpeDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dpeDate;
    }
  }

  factory DpeData.fromJson(Map<String, dynamic> json) {
    json['_id'] ??= json['id'];
    json['adresse_ban'] ??= json['Adresse_brute'];
    json['geo_adresse'] ??= json['Adresse_brute'];
    json['etiquette_dpe'] ??= json['Etiquette_DPE'];
    json['date_etablissement_dpe'] ??= json['Date_établissement_DPE'];
    json['surface_habitable_logement'] ??= json['Surface_habitable_logement'];
    
    // Parse _geopoint which can be in different formats
    final geopoint = json['_geopoint'];
    if (geopoint != null) {
      try {
        if (geopoint is String) {
          // Format: "lat,lng" as string
          if (geopoint.isNotEmpty) {
            final listCoord = geopoint
                .split(',')
                .map((e) => double.tryParse(e.trim()) ?? 0.0)
                .toList();
            if (listCoord.length >= 2) {
              json['latitude'] = listCoord[0];
              json['longitude'] = listCoord[1];
            }
          }
        } else if (geopoint is List) {
          // Format: [lat, lng] as array
          if (geopoint.length >= 2) {
            json['latitude'] = (geopoint[0] as num?)?.toDouble() ?? 48.8566;
            json['longitude'] = (geopoint[1] as num?)?.toDouble() ?? 2.3522;
          }
        } else if (geopoint is Map) {
          // Format: {"lat": ..., "lng": ...} or {"latitude": ..., "longitude": ...}
          json['latitude'] = (geopoint['lat'] as num?)?.toDouble() ??
              (geopoint['latitude'] as num?)?.toDouble() ??
              48.8566;
          json['longitude'] = (geopoint['lng'] as num?)?.toDouble() ??
              (geopoint['longitude'] as num?)?.toDouble() ??
              2.3522;
        }
      } catch (e) {
        // If parsing fails, use default coordinates
        print('Error parsing _geopoint: $e');
        json['latitude'] = 48.8566;
        json['longitude'] = 2.3522;
      }
    }
    
    return _$DpeDataFromJson(json);
  }

  Map<String, dynamic> toJson() => _$DpeDataToJson(this);
}
