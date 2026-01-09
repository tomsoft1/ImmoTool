import 'package:flutter/material.dart';
import '../theme/immo_colors.dart';

/// Custom DVF (transaction) marker widget with badge showing transaction count at address
///
/// Features:
/// - Circular marker with euro icon
/// - Color-coded background (primary teal)
/// - Count badge in top-right corner (gold style)
/// - White border for contrast on all map backgrounds
/// - Drop shadow for depth and clickability indication
class DvfMarkerWithBadge extends StatelessWidget {
  final int count;
  final Color color;

  const DvfMarkerWithBadge({
    super.key,
    required this.count,
    this.color = ImmoColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main DVF marker with euro icon
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                Color.lerp(color, Colors.black, 0.2) ?? color,
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.euro,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),

        // Badge with count (only if count > 1)
        if (count > 1)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: count > 9 ? 4 : 3,
                vertical: 2,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              decoration: BoxDecoration(
                gradient: ImmoColors.secondaryGradient,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: ImmoColors.secondary.withOpacity(0.4),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
