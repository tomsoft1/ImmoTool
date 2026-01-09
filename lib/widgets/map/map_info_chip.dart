import 'package:flutter/material.dart';
import '../../theme/immo_colors.dart';

/// Map information chip widget
///
/// Displays current map status including zoom level, location name,
/// and loading state in an elegant pill-shaped container.
class MapInfoChip extends StatelessWidget {
  final double zoom;
  final String? locationName;
  final bool isLoading;
  final String? layerInfo;

  const MapInfoChip({
    super.key,
    required this.zoom,
    this.locationName,
    this.isLoading = false,
    this.layerInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? ImmoColors.surfaceDark : Colors.white).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Loading indicator or zoom icon
          if (isLoading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ImmoColors.primary,
              ),
            )
          else
            Icon(
              Icons.zoom_in,
              size: 14,
              color: isDark ? Colors.white60 : ImmoColors.tertiaryLight,
            ),

          const SizedBox(width: 6),

          // Zoom level
          Text(
            'x${zoom.toStringAsFixed(1)}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : ImmoColors.tertiaryDark,
            ),
          ),

          // Location name if available
          if (locationName != null && locationName!.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              height: 14,
              color: isDark ? ImmoColors.dividerDark : ImmoColors.divider,
            ),
            Icon(
              Icons.location_on,
              size: 14,
              color: ImmoColors.primary,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                locationName!,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : ImmoColors.tertiaryDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // Layer info if available
          if (layerInfo != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              height: 14,
              color: isDark ? ImmoColors.dividerDark : ImmoColors.divider,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ImmoColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                layerInfo!,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ImmoColors.primary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Simple loading indicator overlay for the map
class MapLoadingOverlay extends StatelessWidget {
  final String? message;

  const MapLoadingOverlay({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? ImmoColors.surfaceDark : Colors.white).withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ImmoColors.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(width: 12),
            Text(
              message!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isDark ? Colors.white : ImmoColors.tertiaryDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
