import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'parcel_data.g.dart';

@JsonSerializable()
class ParcelData {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'commune')
  final String communeCode;

  @JsonKey(name: 'prefixe')
  final String prefix;

  @JsonKey(name: 'section')
  final String section;

  @JsonKey(name: 'numero')
  final String number;

  @JsonKey(name: 'contenance')
  final int area;

  @JsonKey(name: 'geometry')
  final Map<String, dynamic> geometry;

  @JsonKey(name: 'created')
  final String createdDate;

  @JsonKey(name: 'updated')
  final String updatedDate;

  @JsonKey(name: 'id_parcelle', defaultValue: '')
  final String parcelId;

  ParcelData({
    required this.id,
    required this.communeCode,
    required this.prefix,
    required this.section,
    required this.number,
    required this.area,
    required this.geometry,
    required this.createdDate,
    required this.updatedDate,
    required this.parcelId,
  });

  factory ParcelData.fromJson(Map<String, dynamic> json) =>
      _$ParcelDataFromJson(json);
  Map<String, dynamic> toJson() => _$ParcelDataToJson(this);

  List<List<LatLng>> getPolygonPoints() {
    if (geometry['type'] != 'Polygon') return [];

    final coordinates = geometry['coordinates'] as List;
    return coordinates.map<List<LatLng>>((polygon) {
      if (polygon is! List) return [];
      return polygon.map<LatLng>((point) {
        if (point is! List || point.length < 2) return const LatLng(0, 0);
        return LatLng(point[1].toDouble(), point[0].toDouble());
      }).toList();
    }).toList();
  }
}
