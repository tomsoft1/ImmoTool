import 'package:flutter/material.dart';
import 'immo_colors.dart';

/// ImmoTool Theme Configuration
///
/// Provides light and dark theme configurations with consistent styling
class ImmoTheme {
  ImmoTheme._();

  // ============================================
  // Light Theme
  // ============================================

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color Scheme
    colorScheme: ColorScheme.light(
      primary: ImmoColors.primary,
      onPrimary: Colors.white,
      primaryContainer: ImmoColors.primaryLight.withOpacity(0.15),
      onPrimaryContainer: ImmoColors.primaryDark,
      secondary: ImmoColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: ImmoColors.secondaryLight.withOpacity(0.2),
      onSecondaryContainer: ImmoColors.secondaryDark,
      tertiary: ImmoColors.tertiary,
      onTertiary: Colors.white,
      surface: ImmoColors.surface,
      onSurface: ImmoColors.tertiaryDark,
      surfaceContainerHighest: ImmoColors.surfaceVariant,
      error: ImmoColors.error,
      onError: Colors.white,
      outline: ImmoColors.divider,
    ),

    // Scaffold
    scaffoldBackgroundColor: ImmoColors.background,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: ImmoColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.15,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),

    // Card
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ImmoColors.divider),
      ),
      color: ImmoColors.cardBackground,
      clipBehavior: Clip.antiAlias,
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: ImmoColors.surfaceVariant,
      selectedColor: ImmoColors.primary.withOpacity(0.15),
      disabledColor: ImmoColors.surfaceVariant.withOpacity(0.5),
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ImmoColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ImmoColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ImmoColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ImmoColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: ImmoColors.tertiaryLight),
      labelStyle: TextStyle(color: ImmoColors.tertiary),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ImmoColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ImmoColors.primary,
        side: const BorderSide(color: ImmoColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ImmoColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ImmoColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Bottom Sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ImmoColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 8,
      showDragHandle: false,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: ImmoColors.divider,
      thickness: 1,
      space: 1,
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ImmoColors.primary;
        }
        return ImmoColors.tertiaryLight;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ImmoColors.primary.withOpacity(0.3);
        }
        return ImmoColors.divider;
      }),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ImmoColors.tertiaryDark,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: ImmoColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
    ),

    // Icon
    iconTheme: const IconThemeData(
      color: ImmoColors.tertiary,
      size: 24,
    ),

    // Text
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: ImmoColors.tertiaryDark,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: ImmoColors.tertiaryDark,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ImmoColors.tertiaryDark,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ImmoColors.tertiaryDark,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ImmoColors.tertiaryDark,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ImmoColors.tertiaryDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: ImmoColors.tertiary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: ImmoColors.tertiary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: ImmoColors.tertiaryLight,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ImmoColors.tertiary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ImmoColors.tertiary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: ImmoColors.tertiaryLight,
      ),
    ),
  );

  // ============================================
  // Dark Theme
  // ============================================

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Color Scheme
    colorScheme: ColorScheme.dark(
      primary: ImmoColors.primaryLight,
      onPrimary: ImmoColors.primaryDark,
      primaryContainer: ImmoColors.primary.withOpacity(0.25),
      onPrimaryContainer: ImmoColors.primaryLight,
      secondary: ImmoColors.secondaryLight,
      onSecondary: ImmoColors.secondaryDark,
      secondaryContainer: ImmoColors.secondary.withOpacity(0.25),
      onSecondaryContainer: ImmoColors.secondaryLight,
      tertiary: ImmoColors.tertiaryLight,
      onTertiary: Colors.white,
      surface: ImmoColors.surfaceDark,
      onSurface: Colors.white,
      surfaceContainerHighest: ImmoColors.surfaceVariantDark,
      error: ImmoColors.error,
      onError: Colors.white,
      outline: ImmoColors.dividerDark,
    ),

    // Scaffold
    scaffoldBackgroundColor: ImmoColors.backgroundDark,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: ImmoColors.surfaceDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.15,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),

    // Card
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ImmoColors.dividerDark),
      ),
      color: ImmoColors.cardBackgroundDark,
      clipBehavior: Clip.antiAlias,
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: ImmoColors.surfaceVariantDark,
      selectedColor: ImmoColors.primaryLight.withOpacity(0.2),
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide.none,
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ImmoColors.surfaceVariantDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ImmoColors.dividerDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ImmoColors.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ImmoColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ImmoColors.primaryLight,
        foregroundColor: ImmoColors.primaryDark,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Bottom Sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ImmoColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 8,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: ImmoColors.dividerDark,
      thickness: 1,
      space: 1,
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ImmoColors.primaryLight;
        }
        return ImmoColors.tertiaryLight;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ImmoColors.primaryLight.withOpacity(0.3);
        }
        return ImmoColors.dividerDark;
      }),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ImmoColors.surfaceVariantDark,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: ImmoColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
    ),

    // Icon
    iconTheme: const IconThemeData(
      color: Colors.white70,
      size: 24,
    ),

    // Text
    textTheme: TextTheme(
      headlineLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineSmall: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleSmall: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white.withOpacity(0.87),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white.withOpacity(0.87),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Colors.white.withOpacity(0.6),
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.87),
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white.withOpacity(0.87),
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.white.withOpacity(0.6),
      ),
    ),
  );
}
