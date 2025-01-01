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

  factory DpeData.fromJson(Map<String, dynamic> json) => _$DpeDataFromJson(json);
  Map<String, dynamic> toJson() => _$DpeDataToJson(this);
} 