class ImmoDataDvf {
  final String txDate;
  final int txType;
  final int realtyType;
  final double price;
  final DvfAttributes attributes;
  final List<DvfLot> lot;
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
    required this.lot,
    required this.txId,
    required this.squareMeterPrice,
    required this.txGroupId,
    required this.location,
    required this.slug,
  });

  factory ImmoDataDvf.fromJson(Map<String, dynamic> json) {
    return ImmoDataDvf(
      txDate: json['txDate'],
      txType: json['txType'],
      realtyType: json['realtyType'],
      price: json['price'].toDouble(),
      attributes: DvfAttributes.fromJson(json['attributes']),
      lot: (json['lot'] as List).map((e) => DvfLot.fromJson(e)).toList(),
      txId: json['txId'],
      squareMeterPrice: json['squareMeterPrice'].toDouble(),
      txGroupId: json['txGroupId'],
      location: DvfLocation.fromJson(json['location']),
      slug: json['slug'],
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
      rooms: json['rooms'],
      landArea: json['landArea']?.toDouble(),
    );
  }
}

class DvfLot {
  final String parcelId;
  final double landArea;
  final List<DvfRealty> realty;
  final DvfLocation location;

  DvfLot({
    required this.parcelId,
    required this.landArea,
    required this.realty,
    required this.location,
  });

  factory DvfLot.fromJson(Map<String, dynamic> json) {
    return DvfLot(
      parcelId: json['parcelId'],
      landArea: json['landArea'].toDouble(),
      realty:
          (json['realty'] as List).map((e) => DvfRealty.fromJson(e)).toList(),
      location: DvfLocation.fromJson(json['location']),
    );
  }
}

class DvfRealty {
  final int realtyType;
  final double? livingArea;
  final int? rooms;

  DvfRealty({
    required this.realtyType,
    this.livingArea,
    this.rooms,
  });

  factory DvfRealty.fromJson(Map<String, dynamic> json) {
    return DvfRealty(
      realtyType: json['realtyType'],
      livingArea: json['livingArea']?.toDouble(),
      rooms: json['rooms'],
    );
  }
}

class DvfLocation {
  final DvfAddress address;
  final DvfGeometry geometry;
  final bool isDefault;

  DvfLocation({
    required this.address,
    required this.geometry,
    required this.isDefault,
  });

  factory DvfLocation.fromJson(Map<String, dynamic> json) {
    return DvfLocation(
      address: DvfAddress.fromJson(json['address']),
      geometry: DvfGeometry.fromJson(json['geometry']),
      isDefault: json['isDefault'],
    );
  }
}

class DvfAddress {
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

  DvfAddress({
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
  });

  factory DvfAddress.fromJson(Map<String, dynamic> json) {
    return DvfAddress(
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
    );
  }
}

class DvfGeometry {
  final String type;
  final List<double> coordinates;

  DvfGeometry({
    required this.type,
    required this.coordinates,
  });

  double get latitude => coordinates[1];
  double get longitude => coordinates[0];

  factory DvfGeometry.fromJson(Map<String, dynamic> json) {
    return DvfGeometry(
      type: json['type'],
      coordinates: List<double>.from(json['coordinates']),
    );
  }
}
