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

  @JsonKey(name: 'estimation_ges', defaultValue: 0)
  final int gesValue;

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
    required this.gesValue,
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
    json['adresse_complete'] ??= json['Adresse_brute'];
    json['geo_adresse'] ??= json['Adresse_brute'];
    json['classe_consommation_energie'] ??= json['Etiquette_DPE'];
    json['date_etablissement_dpe'] ??= json['Date_établissement_DPE'];
    json['surface_thermique_lot'] ??= json['Surface_habitable_logement'];
    final coordinates = json['_geopoint'] as String;
    if (coordinates.isNotEmpty) {
      final listCoord =
          coordinates.split(',').map((e) => double.parse(e)).toList();

      json['latitude'] = listCoord[0];
      json['longitude'] = listCoord[1];
    }
    return _$DpeDataFromJson(json);
  }

  Map<String, dynamic> toJson() => _$DpeDataToJson(this);
}
