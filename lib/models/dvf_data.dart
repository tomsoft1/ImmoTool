import 'package:json_annotation/json_annotation.dart';

part 'dvf_data.g.dart';

@JsonSerializable()
class DvfData {
  @JsonKey(name: 'id_mutation')
  final String id;

  @JsonKey(name: 'date_mutation')
  final String transactionDate;

  @JsonKey(name: 'nature_mutation')
  final String transactionType;

  @JsonKey(
    name: 'valeur_fonciere',
    fromJson: _parsePrice,
    defaultValue: 0.0
  )
  final double price;

  @JsonKey(name: 'adresse_numero', defaultValue: '')
  final String streetNumber;

  @JsonKey(
    name: 'adresse_suffixe',
    fromJson: _parseSuffix,
    defaultValue: ''
  )
  final String streetSuffix;

  @JsonKey(name: 'adresse_nom_voie', defaultValue: '')
  final String streetName;

  @JsonKey(name: 'code_postal', defaultValue: '')
  final String postalCode;

  @JsonKey(name: 'nom_commune', defaultValue: '')
  final String city;

  @JsonKey(
    name: 'latitude',
    fromJson: _parseCoordinate,
    defaultValue: 0.0
  )
  final double latitude;

  @JsonKey(
    name: 'longitude',
    fromJson: _parseCoordinate,
    defaultValue: 0.0
  )
  final double longitude;

  @JsonKey(
    name: 'surface_reelle_bati',
    fromJson: _parseArea,
    defaultValue: 0.0
  )
  final double buildingArea;

  @JsonKey(
    name: 'nombre_pieces_principales',
    fromJson: _parseRooms,
    defaultValue: 0
  )
  final int numberOfRooms;

  @JsonKey(name: 'type_local', defaultValue: '')
  final String propertyType;

  DvfData({
    required this.id,
    required this.transactionDate,
    required this.transactionType,
    required this.price,
    required this.streetNumber,
    required this.streetSuffix,
    required this.streetName,
    required this.postalCode,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.buildingArea,
    required this.numberOfRooms,
    required this.propertyType,
  });

  String get fullAddress {
    final number = streetNumber.isEmpty ? '' : '$streetNumber ';
    final suffix = streetSuffix.isEmpty ? '' : '$streetSuffix ';
    return '$number$suffix$streetName, $postalCode $city'.trim();
  }

  String get formattedDate {
    if (transactionDate.isEmpty) return 'Date inconnue';
    try {
      final date = DateTime.parse(transactionDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return transactionDate;
    }
  }

  static String _parseSuffix(dynamic value) {
    if (value == null || value == 'none' || value.toString().toLowerCase() == 'none') {
      return '';
    }
    return value.toString();
  }

  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        // Remove any non-numeric characters except decimal point and convert to double
        final cleanString = value.replaceAll(RegExp(r'[^\d.]'), '');
        return double.tryParse(cleanString) ?? 0.0;
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  static double _parseCoordinate(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        // Handle string coordinates that might use comma as decimal separator
        final cleanString = value.trim().replaceAll(',', '.');
        return double.tryParse(cleanString) ?? 0.0;
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  static double _parseArea(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        // Handle string area that might use comma as decimal separator and remove any units
        final cleanString = value.trim()
            .replaceAll(',', '.')
            .replaceAll(RegExp(r'[^\d.]'), '');
        return double.tryParse(cleanString) ?? 0.0;
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  static int _parseRooms(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      try {
        // Remove any non-numeric characters and convert to integer
        return double.parse(value).toInt() ?? 0;
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  factory DvfData.fromJson(Map<String, dynamic> json) => _$DvfDataFromJson(json);
  Map<String, dynamic> toJson() => _$DvfDataToJson(this);
} 