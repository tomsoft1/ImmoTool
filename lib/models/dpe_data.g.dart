// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dpe_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DpeData _$DpeDataFromJson(Map<String, dynamic> json) => DpeData(
      id: json['_id'] as String,
      address: json['adresse_complete'] as String? ?? 'Address unknown',
      geoAddress: json['geo_adresse'] as String? ?? '',
      dpeDate: json['date_etablissement_dpe'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 48.8566,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 2.3522,
      energyGrade: json['classe_consommation_energie'] as String? ?? 'N/A',
      energyValue: (json['conso_energie'] as num?)?.toInt() ?? 0,
      gesGrade: json['classe_estimation_ges'] as String? ?? 'N/A',
      gesValue: (json['estimation_ges'] as num?)?.toInt() ?? 0,
      surface: (json['surface_thermique_lot'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$DpeDataToJson(DpeData instance) => <String, dynamic>{
      '_id': instance.id,
      'adresse_complete': instance.address,
      'geo_adresse': instance.geoAddress,
      'date_etablissement_dpe': instance.dpeDate,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'classe_consommation_energie': instance.energyGrade,
      'conso_energie': instance.energyValue,
      'classe_estimation_ges': instance.gesGrade,
      'estimation_ges': instance.gesValue,
      'surface_thermique_lot': instance.surface,
    };
