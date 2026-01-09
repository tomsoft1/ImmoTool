import 'package:flutter/material.dart';

/// Custom DVF (transaction) marker widget with badge showing transaction count at address
///
/// Features:
/// - Circular blue marker with euro icon
/// - Color-coded background (blue for transactions)
/// - Count badge in top-right corner (red notification style)
/// - White border for contrast on all map backgrounds
/// - Drop shadow for depth and clickability indication
class DvfMarkerWithBadge extends StatelessWidget {
  final int count;
  final Color color;

  const DvfMarkerWithBadge({
    super.key,
    required this.count,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main DVF marker (euro icon)
        Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.euro,
              color: Colors.white,
              size: 20,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),

        // Badge with count (only if count > 1)
        if (count > 1)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
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
