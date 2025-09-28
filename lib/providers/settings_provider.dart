import 'package:flutter/foundation.dart';

enum DateRange {
  last3Months,
  last6Months,
  custom,
}

class SettingsProvider with ChangeNotifier {
  final Set<String> _selectedDpeGrades = {'F', 'G'};
  int _minSurface = 0;
  int _maxSurface = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  DateRange _dateRange = DateRange.last3Months;

  Set<String> get selectedDpeGrades => _selectedDpeGrades;
  int get minSurface => _minSurface;
  int get maxSurface => _maxSurface;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  DateRange get dateRange => _dateRange;

  void toggleDpeGrade(String grade) {
    if (_selectedDpeGrades.contains(grade)) {
      _selectedDpeGrades.remove(grade);
    } else {
      _selectedDpeGrades.add(grade);
    }
    notifyListeners();
  }

  void setDateRange(DateRange range) {
    _dateRange = range;
    final now = DateTime.now();

    switch (range) {
      case DateRange.last3Months:
        _startDate = DateTime(now.year, now.month - 3, now.day);
        _endDate = now;
        break;
      case DateRange.last6Months:
        _startDate = DateTime(now.year, now.month - 6, now.day);
        _endDate = now;
        break;
      case DateRange.custom:
        // Keep existing custom dates
        break;
    }

    notifyListeners();
  }

  void updateSettings({
    required int minSurface,
    required int maxSurface,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _minSurface = minSurface;
    _maxSurface = maxSurface;
    if (_dateRange == DateRange.custom) {
      _startDate = startDate;
      _endDate = endDate;
    }
    notifyListeners();
  }

  String getDateRangeQuery() {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (_dateRange) {
      case DateRange.last3Months:
        start = DateTime(now.year, now.month - 3, now.day);
        break;
      case DateRange.last6Months:
        start = DateTime(now.year, now.month - 6, now.day);
        break;
      case DateRange.custom:
        start = _startDate ?? DateTime(now.year, now.month - 3, now.day);
        end = _endDate ?? now;
        break;
    }

    return 'date_etablissement_dpe:[${start.toString().split(' ')[0]} TO ${end.toString().split(' ')[0]}]';
  }

  String getDpeGradesQuery() {
    if (_selectedDpeGrades.isEmpty) return '';
    return 'etiquette_dpe:(${_selectedDpeGrades.map((g) => '"$g"').join(' OR ')})';
  }

  String getSurfaceQuery() {
    if (_minSurface == 0 && _maxSurface == 0) return '';
    final List<String> conditions = [];
    if (_minSurface > 0) {
      conditions.add('surface_thermique_lot:>=$_minSurface');
    }
    if (_maxSurface > 0) {
      conditions.add('surface_thermique_lot:<=$_maxSurface');
    }
    return conditions.join(' AND ');
  }

  String getFullQuery() {
    final List<String> conditions = [];

    final dpeGradesQuery = getDpeGradesQuery();
    if (dpeGradesQuery.isNotEmpty) {
      conditions.add(dpeGradesQuery);
    }

    final dateRangeQuery = getDateRangeQuery();
    if (dateRangeQuery.isNotEmpty) {
      conditions.add(dateRangeQuery);
    }

    final surfaceQuery = getSurfaceQuery();
    if (surfaceQuery.isNotEmpty) {
      conditions.add(surfaceQuery);
    }

    return conditions.join(' AND ');
  }
}
