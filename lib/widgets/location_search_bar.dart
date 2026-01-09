import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geocoding/geocoding.dart';
import '../services/geo_api_service.dart';
//import 'dart:developer';

/// Represents a search result that can be either a commune or an address
class SearchResult {
  final String name;
  final String? subtitle;
  final double latitude;
  final double longitude;
  final bool isAddress;
  final Commune? commune; // Store original commune if available

  SearchResult({
    required this.name,
    this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.isAddress,
    this.commune,
  });

  factory SearchResult.fromCommune(Commune commune, String departmentName) {
    return SearchResult(
      name: commune.name,
      subtitle: '${commune.postalCode} - $departmentName',
      latitude: commune.latitude,
      longitude: commune.longitude,
      isAddress: false,
      commune: commune,
    );
  }
}

class LocationSearchBar extends StatefulWidget {
  final Function(Commune) onCommuneSelected;
  final Function(double latitude, double longitude)? onAddressSelected;

  const LocationSearchBar({
    super.key,
    required this.onCommuneSelected,
    this.onAddressSelected,
  });

  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  final GeoApiService _geoApiService = GeoApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Department> _departments = [];
  List<SearchResult> _searchResults = [];
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await _geoApiService.getDepartments();
      //print(departments[0].geometry);
      setState(() {
        _departments = departments;
      });
    } catch (e) {
      debugPrint('Error loading departments: $e');
    }
  }

  Future<void> _searchLocation(String query) async {
    final debounce = _debounce;
    if (debounce != null && debounce.isActive) {
      debounce.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final List<SearchResult> results = [];

        // First, try to search for addresses using geocoding
        try {
          final locations =
              await locationFromAddress(query, localeIdentifier: 'fr_FR');
          if (locations.isNotEmpty) {
            // Limit to first 5 address results
            for (final location in locations.take(5)) {
              try {
                // Validate location coordinates
                final lat = location.latitude;
                final lng = location.longitude;

                if (lat.isNaN ||
                    lng.isNaN ||
                    lat.isInfinite ||
                    lng.isInfinite) {
                  debugPrint('Invalid location coordinates: $lat, $lng');
                  continue;
                }

                // Try to get placemark details, but handle errors gracefully
                List<Placemark> placemarks = [];
                try {
                  placemarks = await placemarkFromCoordinates(
                    lat,
                    lng,
                    localeIdentifier: 'fr_FR',
                  );
                } catch (placemarkError) {
                  debugPrint(
                      'Could not get placemark details: $placemarkError');
                  // Continue without placemark details - we'll use coordinates
                }

                String addressName = 'Adresse trouvée';
                final addressParts = <String>[];

                if (placemarks.isNotEmpty) {
                  try {
                    final placemark = placemarks.first;
                    // Build address string
                    final street = placemark.street;
                    if (street != null && street.isNotEmpty) {
                      addressParts.add(street);
                      addressName = street;
                    }

                    final postalCode = placemark.postalCode;
                    if (postalCode != null && postalCode.isNotEmpty) {
                      addressParts.add(postalCode);
                    }

                    final locality = placemark.locality;
                    if (locality != null && locality.isNotEmpty) {
                      addressParts.add(locality);
                    }

                    // Use placemark name as fallback if no street
                    if (addressName == 'Adresse trouvée') {
                      final placemarkName = placemark.name;
                      if (placemarkName != null && placemarkName.isNotEmpty) {
                        addressName = placemarkName;
                      }
                    }
                  } catch (placemarkParseError) {
                    debugPrint('Error parsing placemark: $placemarkParseError');
                    // Use coordinates as fallback
                  }
                }

                // If we still don't have address details, use coordinates
                if (addressParts.isEmpty) {
                  addressParts.add(
                      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}');
                }

                results.add(SearchResult(
                  name: addressName,
                  subtitle:
                      addressParts.isNotEmpty ? addressParts.join(', ') : null,
                  latitude: lat,
                  longitude: lng,
                  isAddress: true,
                ));
              } catch (e, stackTrace) {
                debugPrint('Error getting placemark for location: $e');
                debugPrint('Stack trace: $stackTrace');
                // If placemark fails, still add the location with coordinates
                try {
                  results.add(SearchResult(
                    name: 'Adresse trouvée',
                    subtitle:
                        '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                    latitude: location.latitude,
                    longitude: location.longitude,
                    isAddress: true,
                  ));
                } catch (addError) {
                  debugPrint('Error adding fallback result: $addError');
                }
              }
            }
          }
        } catch (e, stackTrace) {
          debugPrint('Error searching addresses: $e');
          debugPrint('Stack trace: $stackTrace');
          // Continue to commune search as fallback
        }

        // Also search for communes as fallback/complement
        try {
          final communes = await _geoApiService.searchCommunes(query);
          for (final commune in communes.take(5)) {
            final department = _departments.firstWhere(
              (d) => d.code == commune.department,
              orElse: () => Department(code: '', name: '', region: ''),
            );
            results.add(SearchResult.fromCommune(commune, department.name));
          }
        } catch (e) {
          debugPrint('Error searching communes: $e');
        }

        // Remove duplicates and limit total results
        final uniqueResults = <String, SearchResult>{};
        for (final result in results) {
          final key = '${result.latitude}_${result.longitude}';
          if (!uniqueResults.containsKey(key)) {
            uniqueResults[key] = result;
          }
        }

        setState(() {
          _searchResults = uniqueResults.values.take(10).toList();
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('Error searching location: $e');
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une ville ou une adresse...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchLocation(value);
              });
            },
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        if (_searchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  leading: Icon(
                    result.isAddress ? Icons.location_on : Icons.location_city,
                    color: result.isAddress ? Colors.blue : Colors.grey,
                  ),
                  title: Text(result.name),
                  subtitle:
                      result.subtitle != null && result.subtitle!.isNotEmpty
                          ? Text(result.subtitle!)
                          : null,
                  onTap: () {
                    if (result.isAddress) {
                      // Handle address selection
                      final onAddressSelected = widget.onAddressSelected;
                      if (onAddressSelected != null) {
                        onAddressSelected(
                          result.latitude,
                          result.longitude,
                        );
                      }
                    } else {
                      // Handle commune selection
                      final commune = result.commune;
                      if (commune != null) {
                        widget.onCommuneSelected(commune);
                      }
                    }
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
