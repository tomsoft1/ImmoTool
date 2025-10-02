// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parcel_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParcelData _$ParcelDataFromJson(Map<String, dynamic> json) => ParcelData(
    id: json['id'] as String,
    communeCode: json['commune'] as String,
    prefix: json['prefixe'] as String,
    section: json['section'] as String,
    number: json['numero'] as String,
    area: (json['contenance'] as num).toInt(),
    geometry: json['geometry'] as Map<String, dynamic>,
    createdDate: json['created'] as String,
    updatedDate: json['updated'] as String);

Map<String, dynamic> _$ParcelDataToJson(ParcelData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'commune': instance.communeCode,
      'prefixe': instance.prefix,
      'section': instance.section,
      'numero': instance.number,
      'contenance': instance.area,
      'geometry': instance.geometry,
      'created': instance.createdDate,
      'updated': instance.updatedDate
    };
