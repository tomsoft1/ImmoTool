// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dvf_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DvfData _$DvfDataFromJson(Map<String, dynamic> json) => DvfData(
      id: json['id_mutation'] as String,
      transactionDate: json['date_mutation'] as String,
      transactionType: json['nature_mutation'] as String,
      price: json['valeur_fonciere'] == null
          ? 0.0
          : DvfData._parsePrice(json['valeur_fonciere']),
      streetNumber: json['adresse_numero'] as String? ?? '',
      streetSuffix: json['adresse_suffixe'] == null
          ? ''
          : DvfData._parseSuffix(json['adresse_suffixe']),
      streetName: json['adresse_nom_voie'] as String? ?? '',
      postalCode: json['code_postal'] as String? ?? '',
      city: json['nom_commune'] as String? ?? '',
      latitude: json['latitude'] == null
          ? 0.0
          : DvfData._parseCoordinate(json['latitude']),
      longitude: json['longitude'] == null
          ? 0.0
          : DvfData._parseCoordinate(json['longitude']),
      buildingArea: json['surface_reelle_bati'] == null
          ? 0.0
          : DvfData._parseArea(json['surface_reelle_bati']),
      numberOfRooms: json['nombre_pieces_principales'] == null
          ? 0
          : DvfData._parseRooms(json['nombre_pieces_principales']),
      propertyType: json['type_local'] as String? ?? '',
      section: json['section_cadastrale'] as String? ?? '',
    );

Map<String, dynamic> _$DvfDataToJson(DvfData instance) => <String, dynamic>{
      'id_mutation': instance.id,
      'date_mutation': instance.transactionDate,
      'nature_mutation': instance.transactionType,
      'valeur_fonciere': instance.price,
      'adresse_numero': instance.streetNumber,
      'adresse_suffixe': instance.streetSuffix,
      'adresse_nom_voie': instance.streetName,
      'code_postal': instance.postalCode,
      'nom_commune': instance.city,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'surface_reelle_bati': instance.buildingArea,
      'nombre_pieces_principales': instance.numberOfRooms,
      'type_local': instance.propertyType,
      'section_cadastrale': instance.section,
    };
