import 'package:flutter/material.dart';
import '../../theme/immo_colors.dart';

/// Unified map control panel widget
///
/// Displays zoom in/out, compass, and location controls
/// in a single elegant vertical container.
class MapControlPanel extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onLocate;
  final VoidCallback? onCompass;
  final bool isLocating;

  const MapControlPanel({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLocate,
    this.onCompass,
    this.isLocating = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: (isDark ? ImmoColors.surfaceDark : Colors.white).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ControlButton(
            icon: Icons.add,
            onTap: onZoomIn,
            tooltip: 'Zoom avant',
          ),
          _Divider(isDark: isDark),
          _ControlButton(
            icon: Icons.remove,
            onTap: onZoomOut,
            tooltip: 'Zoom arriere',
          ),
          if (onCompass != null) ...[
            _Divider(isDark: isDark),
            _ControlButton(
              icon: Icons.explore_outlined,
              onTap: onCompass!,
              tooltip: 'Orienter au nord',
            ),
          ],
          _Divider(isDark: isDark),
          _ControlButton(
            icon: isLocating ? Icons.gps_fixed : Icons.my_location,
            onTap: onLocate,
            tooltip: 'Ma position',
            highlighted: true,
            isLoading: isLocating,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool highlighted;
  final bool isLoading;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.highlighted = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ImmoColors.primary,
                    ),
                  )
                : Icon(
                    icon,
                    size: 22,
                    color: highlighted
                        ? ImmoColors.primary
                        : (isDark ? Colors.white70 : ImmoColors.tertiary),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;

  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: 28,
      color: isDark ? ImmoColors.dividerDark : ImmoColors.divider,
    );
  }
}
