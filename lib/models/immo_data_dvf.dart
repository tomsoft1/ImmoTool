class ImmoDataDvf {
  final String txDate;
  final int txType;
  final int realtyType;
  final double price;
  final DvfAttributes attributes;
  final String txId;
  final double squareMeterPrice;
  final String txGroupId;
  final DvfLocation location;
  final String slug;

  ImmoDataDvf({
    required this.txDate,
    required this.txType,
    required this.realtyType,
    required this.price,
    required this.attributes,
    required this.txId,
    required this.squareMeterPrice,
    required this.txGroupId,
    required this.location,
    required this.slug,
  });

  factory ImmoDataDvf.fromJson(Map<String, dynamic> json) {
    // Calculer le prix au m² si possible
    double squareMeterPrice = 0.0;
    double surface = 0.0;
    double price = 0.0;
    if (json['valeur_fonciere'] != null) {
      price = double.tryParse(json['valeur_fonciere'].toString()) ?? 0.0;
    }
    if (json['lot1_surface_carrez'] != null) {
      surface = double.tryParse(json['lot1_surface_carrez'].toString()) ?? 0.0;
      if (surface > 0) {
        squareMeterPrice = price / surface;
      }
    }

    // Créer les attributs à partir des nouveaux champs
    final attributes = DvfAttributes(
      livingArea: surface,
      rooms: json['nombre_pieces_principales'] != null
          ? double.tryParse(json['nombre_pieces_principales'].toString())
              ?.toInt()
          : null,
      landArea:
          json['surface_terrain'] != null && json['surface_terrain'] != 'nan'
              ? double.tryParse(json['surface_terrain'].toString())
              : null,
    );

    // Créer le lot à partir des nouveaux champs
    if (json['id_parcelle'] != null) {}

    return ImmoDataDvf(
      txDate: json['date_mutation']?.toString() ?? '',
      txType: 1, // Valeur par défaut pour "Vente"
      realtyType: json['code_type_local'] != null
          ? int.tryParse(json['code_type_local'].toString()) ?? 0
          : 0,
      price: price,
      attributes: attributes,
      txId: json['id_mutation']?.toString() ?? '',
      squareMeterPrice: squareMeterPrice,
      txGroupId: json['id_mutation']?.toString() ?? '',
      location: DvfLocation(
        addressId: json['id_parcelle']?.toString() ?? '',
        streetNumber: json['adresse_numero']?.toString() ?? '',
        streetSuffix: json['adresse_suffixe']?.toString() ?? '',
        streetType: '',
        streetName: json['adresse_nom_voie']?.toString() ?? '',
        streetCode: json['adresse_code_voie']?.toString() ?? '',
        postCode: json['code_postal']?.toString() ?? '',
        cityName: json['nom_commune']?.toString() ?? '',
        departmentCode: json['code_departement']?.toString() ?? '',
        inseeCode: json['code_commune']?.toString() ?? '',
        districtCode: '',
        subdistrictCode: '',
        longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
        latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
        isDefault: true,
      ),
      slug: json['id_mutation']?.toString() ?? '',
    );
  }
}

class DvfAttributes {
  final double? livingArea;
  final int? rooms;
  final double? landArea;

  DvfAttributes({
    this.livingArea,
    this.rooms,
    this.landArea,
  });

  factory DvfAttributes.fromJson(Map<String, dynamic> json) {
    return DvfAttributes(
      livingArea: json['livingArea']?.toDouble(),
      rooms: json['rooms'] | "n/a",
      landArea: json['landArea']?.toDouble(),
    );
  }
}

class DvfLot {
  final String parcelId;
  final double landArea;
  final DvfLocation location;

  DvfLot({
    required this.parcelId,
    required this.landArea,
    required this.location,
  });

  factory DvfLot.fromJson(Map<String, dynamic> json) {
    return DvfLot(
      parcelId: json['parcelId'],
      landArea: json['landArea'].toDouble(),
      location: DvfLocation.fromJson(json['location']),
    );
  }
}

class DvfLocation {
  final String addressId;
  final String streetNumber;
  final String streetSuffix;
  final String streetType;
  final String streetName;
  final String streetCode;
  final String postCode;
  final String cityName;
  final String departmentCode;
  final String inseeCode;
  final String districtCode;
  final String subdistrictCode;
  final double longitude;
  final double latitude;

  final bool isDefault;

  DvfLocation({
    required this.addressId,
    required this.streetNumber,
    required this.streetSuffix,
    required this.streetType,
    required this.streetName,
    required this.streetCode,
    required this.postCode,
    required this.cityName,
    required this.departmentCode,
    required this.inseeCode,
    required this.districtCode,
    required this.subdistrictCode,
    required this.longitude,
    required this.latitude,
    required this.isDefault,
  });

  factory DvfLocation.fromJson(Map<String, dynamic> json) {
    return DvfLocation(
      addressId: json['addressId'],
      streetNumber: json['streetNumber'],
      streetSuffix: json['streetSuffix'],
      streetType: json['streetType'],
      streetName: json['streetName'],
      streetCode: json['streetCode'],
      postCode: json['postCode'],
      cityName: json['cityName'],
      departmentCode: json['departmentCode'],
      inseeCode: json['inseeCode'],
      districtCode: json['districtCode'],
      subdistrictCode: json['subdistrictCode'],
      longitude: json['longitude'],
      latitude: json['latitude'],
      isDefault: json['isDefault'],
    );
  }
}
