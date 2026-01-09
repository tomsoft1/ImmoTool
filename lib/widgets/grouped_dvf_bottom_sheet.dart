import 'package:flutter/material.dart';
import '../models/immo_data_dvf.dart';
import 'dvf_info_card.dart';

/// Material 3 bottom sheet for displaying grouped DVF transactions at same address
///
/// Features:
/// - Drag handle for scroll indication
/// - Header with address and statistics (count, avg price, price range)
/// - Property type distribution
/// - Scrollable list of all transactions with DvfInfoCard
/// - Material 3 design with primary container colors
class GroupedDvfBottomSheet extends StatelessWidget {
  final List<ImmoDataDvf> dvfList;

  const GroupedDvfBottomSheet({
    super.key,
    required this.dvfList,
  });

  String _getPropertyTypeName(int typeCode) {
    switch (typeCode) {
      case 1:
        return 'Appart.';
      case 2:
        return 'Maison';
      case 3:
        return 'Commercial';
      case 4:
        return 'Dépendance';
      default:
        return 'Autre';
    }
  }

  Color _getPropertyTypeColor(int typeCode) {
    switch (typeCode) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Map<String, int> _getTypeDistribution() {
    final distribution = <String, int>{};
    for (final dvf in dvfList) {
      final typeName = _getPropertyTypeName(dvf.realtyType);
      distribution[typeName] = (distribution[typeName] ?? 0) + 1;
    }
    return distribution;
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(2)}M€';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K€';
    } else {
      return '${price.toStringAsFixed(0)}€';
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = dvfList.first.location.cityName;
    final distribution = _getTypeDistribution();
    final avgPrice =
        dvfList.map((d) => d.price).reduce((a, b) => a + b) / dvfList.length;
    final minPrice = dvfList.map((d) => d.price).reduce((a, b) => a < b ? a : b);
    final maxPrice = dvfList.map((d) => d.price).reduce((a, b) => a > b ? a : b);

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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatChip(
                        icon: Icons.home_work,
                        label: '${dvfList.length}',
                        subtitle: 'transactions',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.trending_up,
                        label: _formatPrice(avgPrice),
                        subtitle: 'prix moyen',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.price_change,
                        label: '${_formatPrice(minPrice)}-${_formatPrice(maxPrice)}',
                        subtitle: 'fourchette',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),

                // Type distribution
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: distribution.entries.map((entry) {
                    final typeCode = dvfList
                        .firstWhere(
                          (d) => _getPropertyTypeName(d.realtyType) == entry.key,
                        )
                        .realtyType;
                    final color = _getPropertyTypeColor(typeCode);

                    return Chip(
                      label: Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: color.withValues(alpha: 0.2),
                      side: BorderSide(
                        color: color,
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

          // Transaction list
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              itemCount: dvfList.length,
              separatorBuilder: (context, index) => const Divider(
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                return DvfInfoCard(
                  dvf: dvfList[index],
                  index: index + 1,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
