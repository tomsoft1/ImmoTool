import 'package:flutter/material.dart';
import '../models/dpe_data.dart';

/// Reusable card widget displaying DPE information for a single property
///
/// Used in:
/// - GroupedDpeBottomSheet for multiple properties at same address
/// - Single property bottom sheet for consistent design
///
/// Features:
/// - Color-coded badge with energy grade
/// - Icon-based info rows for better readability
/// - Subtle background color matching DPE grade
/// - Rounded corners and border for modern look
class PropertyInfoCard extends StatelessWidget {
  final DpeData dpe;
  final int index;
  final Color color;

  const PropertyInfoCard({
    super.key,
    required this.dpe,
    required this.index,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with grade and index
          Row(
            children: [
              // Grade badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dpe.energyGrade.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  'Logement #$index',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Info rows
          _InfoRow(
            icon: Icons.bolt,
            label: 'Consommation',
            value: '${dpe.energyValue} kWh/m²/an',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.co2,
            label: 'GES',
            value: 'Classe ${dpe.gesGrade}',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.square_foot,
            label: 'Surface',
            value: '${dpe.surface.toStringAsFixed(1)} m²',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.calendar_today,
            label: 'Date DPE',
            value: dpe.formattedDate,
          ),
        ],
      ),
    );
  }
}

/// Internal widget for info rows with icon, label and value
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
