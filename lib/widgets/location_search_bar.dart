import 'package:flutter/material.dart';
import 'dart:async';
import '../services/geo_api_service.dart';
import 'dart:developer';

class LocationSearchBar extends StatefulWidget {
  final Function(Commune) onCommuneSelected;

  const LocationSearchBar({
    super.key,
    required this.onCommuneSelected,
  });

  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  final GeoApiService _geoApiService = GeoApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Department> _departments = [];
  List<Commune> _searchResults = [];
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
    if (_debounce?.isActive ?? false) _debounce!.cancel();

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
        final results = await _geoApiService.searchCommunes(query);
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('Error searching communes: $e');
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
              hintText: 'Search for a city...',
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
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final commune = _searchResults[index];
                final department = _departments.firstWhere(
                  (d) => d.code == commune.department,
                  orElse: () => Department(code: '', name: '', region: ''),
                );
                return ListTile(
                  title: Text(commune.name),
                  subtitle: Text('${commune.postalCode} - ${department.name}'),
                  onTap: () {
                    widget.onCommuneSelected(commune);
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
