import 'package:flutter/material.dart';
import '../models/dpe_data.dart';
import 'property_info_card.dart';

/// Material 3 bottom sheet for displaying grouped DPE data at same address
///
/// Features:
/// - Drag handle for scroll indication
/// - Header with address and statistics (count, avg energy)
/// - Grade distribution chips (A/B/C counts)
/// - Scrollable list of all properties with PropertyInfoCard
/// - Material 3 design with primary container colors
class GroupedDpeBottomSheet extends StatelessWidget {
  final List<DpeData> dpeList;

  const GroupedDpeBottomSheet({
    super.key,
    required this.dpeList,
  });

  Color _getDpeColor(String energyGrade) {
    switch (energyGrade.toUpperCase()) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.yellow.shade700;
      case 'D':
        return Colors.orange;
      case 'E':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      case 'G':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  Map<String, int> _getGradeDistribution() {
    final distribution = <String, int>{};
    for (final dpe in dpeList) {
      final grade = dpe.energyGrade.toUpperCase();
      distribution[grade] = (distribution[grade] ?? 0) + 1;
    }
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    final address = dpeList.first.address;
    final distribution = _getGradeDistribution();
    final avgEnergy =
        dpeList.map((d) => d.energyValue).reduce((a, b) => a + b) /
            dpeList.length;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with address and stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Statistics row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(
                      icon: Icons.home,
                      label: '${dpeList.length}',
                      subtitle: 'logements',
                      color: Colors.blue,
                    ),
                    _StatChip(
                      icon: Icons.bolt,
                      label: '${avgEnergy.round()}',
                      subtitle: 'kWh/m²/an',
                      color: Colors.orange,
                    ),
                  ],
                ),

                // Grade distribution
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: distribution.entries.map((entry) {
                    return Chip(
                      label: Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor:
                          _getDpeColor(entry.key).withValues(alpha: 0.2),
                      side: BorderSide(
                        color: _getDpeColor(entry.key),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Property list
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              itemCount: dpeList.length,
              separatorBuilder: (context, index) => const Divider(
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                return PropertyInfoCard(
                  dpe: dpeList[index],
                  index: index + 1,
                  color: _getDpeColor(dpeList[index].energyGrade),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Statistic chip widget showing icon, value and subtitle
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
