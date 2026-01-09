import 'package:flutter/material.dart';

/// ImmoTool Color Palette
///
/// Professional color scheme for French real estate visualization
class ImmoColors {
  ImmoColors._();

  // ============================================
  // Brand Colors
  // ============================================

  /// Primary: Deep Teal - Professional, trustworthy
  static const Color primary = Color(0xFF0D6E6E);
  static const Color primaryLight = Color(0xFF4A9D9D);
  static const Color primaryDark = Color(0xFF004D4D);

  /// Secondary: Warm Gold - Premium, quality
  static const Color secondary = Color(0xFFD4A84B);
  static const Color secondaryLight = Color(0xFFEAC87C);
  static const Color secondaryDark = Color(0xFFB08B2D);

  /// Tertiary: Slate - Modern, sophisticated
  static const Color tertiary = Color(0xFF4A5568);
  static const Color tertiaryLight = Color(0xFF718096);
  static const Color tertiaryDark = Color(0xFF2D3748);

  // ============================================
  // Surface Colors - Light Mode
  // ============================================

  static const Color background = Color(0xFFF8FAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F4);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE2E8E8);

  // ============================================
  // Surface Colors - Dark Mode
  // ============================================

  static const Color backgroundDark = Color(0xFF0F1419);
  static const Color surfaceDark = Color(0xFF1A2027);
  static const Color surfaceVariantDark = Color(0xFF252D35);
  static const Color cardBackgroundDark = Color(0xFF1E262E);
  static const Color dividerDark = Color(0xFF3A4550);

  // ============================================
  // Semantic Colors
  // ============================================

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ============================================
  // DPE Grade Colors (Official French DPE)
  // ============================================

  static const Map<String, Color> dpeColors = {
    'A': Color(0xFF319834),  // Green
    'B': Color(0xFF33CC31),  // Light Green
    'C': Color(0xFFC8D900),  // Yellow-Green
    'D': Color(0xFFFFED00),  // Yellow
    'E': Color(0xFFFAB600),  // Orange
    'F': Color(0xFFEB8C00),  // Deep Orange
    'G': Color(0xFFD7221F),  // Red
  };

  /// Get DPE color for a specific grade
  static Color getDpeColor(String grade) {
    return dpeColors[grade.toUpperCase()] ?? Colors.grey;
  }

  /// Get text color for DPE grade (white for dark backgrounds)
  static Color getDpeTextColor(String grade) {
    final darkGrades = ['A', 'B', 'F', 'G'];
    return darkGrades.contains(grade.toUpperCase())
        ? Colors.white
        : Colors.black87;
  }

  // ============================================
  // Property Type Colors
  // ============================================

  static const Color apartment = Color(0xFF3B82F6);   // Blue
  static const Color house = Color(0xFF10B981);       // Green
  static const Color commercial = Color(0xFFF59E0B); // Orange
  static const Color dependency = Color(0xFF8B5CF6); // Purple
  static const Color land = Color(0xFF6B7280);       // Gray

  /// Get color for property type code
  static Color getPropertyTypeColor(int typeCode) {
    switch (typeCode) {
      case 1: return apartment;
      case 2: return house;
      case 3: return commercial;
      case 4: return dependency;
      case 5: return land;
      default: return Colors.grey;
    }
  }

  /// Get property type name
  static String getPropertyTypeName(int typeCode) {
    switch (typeCode) {
      case 1: return 'Appartement';
      case 2: return 'Maison';
      case 3: return 'Local commercial';
      case 4: return 'Dependance';
      case 5: return 'Terrain';
      default: return 'Autre';
    }
  }

  // ============================================
  // Map Colors
  // ============================================

  /// Department boundary colors
  static Color get departmentFill => primary.withOpacity(0.08);
  static Color get departmentBorder => primaryDark.withOpacity(0.4);

  /// Commune boundary colors
  static Color get communeFill => success.withOpacity(0.1);
  static Color get communeBorder => success.withOpacity(0.6);

  /// Parcel boundary colors
  static Color get parcelFill => primary.withOpacity(0.12);
  static Color get parcelBorder => primary.withOpacity(0.5);
  static Color get parcelSelectedFill => primary.withOpacity(0.25);
  static Color get parcelSelectedBorder => primary;

  // ============================================
  // Gradients
  // ============================================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  static LinearGradient get appBarGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, primaryDark],
  );
}
