import 'package:flutter/material.dart';
import '../theme/immo_colors.dart';

/// Custom DPE marker widget with badge showing property count at address
///
/// Features:
/// - Circular marker with energy grade letter (A-G)
/// - Color-coded background based on DPE grade with gradient
/// - Count badge in top-right corner (gold style)
/// - White border for contrast on all map backgrounds
/// - Drop shadow for depth and clickability indication
class DpeMarkerWithBadge extends StatelessWidget {
  final String energyGrade;
  final int count;
  final Color color;

  const DpeMarkerWithBadge({
    super.key,
    required this.energyGrade,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = ImmoColors.getDpeTextColor(energyGrade);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main DPE marker with gradient
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                Color.lerp(color, Colors.black, 0.15) ?? color,
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              energyGrade.toUpperCase(),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Badge with count (only if count > 1)
        if (count > 1)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: count > 9 ? 5 : 4,
                vertical: 3,
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              decoration: BoxDecoration(
                gradient: ImmoColors.secondaryGradient,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: ImmoColors.secondary.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
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
