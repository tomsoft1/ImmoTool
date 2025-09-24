import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

abstract class RealEstateDataService<T> {
  /// Récupère les données immobilières dans une zone géographique donnée
  ///
  /// [bounds] définit les limites de la zone de recherche
  /// [minDate] et [maxDate] définissent la plage de dates pour les données
  /// [minSurface] et [maxSurface] définissent la plage de surface habitable
  /// [minPrice] et [maxPrice] définissent la plage de prix
  Future<List<T>> getData({
    required LatLngBounds bounds,
    DateTime? minDate,
    DateTime? maxDate,
    double? minSurface,
    double? maxSurface,
    double? minPrice,
    double? maxPrice,
  });

  /// Convertit les données brutes en marqueurs pour la carte
  List<Marker> convertToMarkers(BuildContext context, List<T> data);

  /// Vérifie si le service est disponible
  Future<bool> isAvailable();

  /// Récupère les détails d'une propriété spécifique
  Future<Map<String, dynamic>?> getPropertyDetails(String id);
}
