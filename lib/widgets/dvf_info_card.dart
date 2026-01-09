import 'package:flutter/material.dart';
import '../models/immo_data_dvf.dart';

/// Reusable card widget displaying DVF (transaction) information
///
/// Used in:
/// - GroupedDvfBottomSheet for multiple transactions at same address
/// - Single transaction bottom sheet for consistent design
///
/// Features:
/// - Price badge with formatted currency
/// - Icon-based info rows for better readability
/// - Property type indicator
/// - Rounded corners and border for modern look
class DvfInfoCard extends StatelessWidget {
  final ImmoDataDvf dvf;
  final int index;

  const DvfInfoCard({
    super.key,
    required this.dvf,
    required this.index,
  });

  String _getPropertyTypeName(int typeCode) {
    switch (typeCode) {
      case 1:
        return 'Appartement';
      case 2:
        return 'Maison';
      case 3:
        return 'Local commercial';
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

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(2)}M€';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K€';
    } else {
      return '${price.toStringAsFixed(0)}€';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyType = _getPropertyTypeName(dvf.realtyType);
    final typeColor = _getPropertyTypeColor(dvf.realtyType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with price and type
          Row(
            children: [
              // Price badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatPrice(dvf.price),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  propertyType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),

              const Spacer(),

              // Transaction number
              Text(
                '#$index',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Info rows
          if (dvf.squareMeterPrice > 0)
            _InfoRow(
              icon: Icons.analytics,
              label: 'Prix au m²',
              value: '${dvf.squareMeterPrice.toStringAsFixed(0)}€/m²',
            ),
          if (dvf.squareMeterPrice > 0) const SizedBox(height: 8),

          if (dvf.attributes.livingArea != null && dvf.attributes.livingArea! > 0)
            _InfoRow(
              icon: Icons.square_foot,
              label: 'Surface',
              value: '${dvf.attributes.livingArea!.toStringAsFixed(1)} m²',
            ),
          if (dvf.attributes.livingArea != null && dvf.attributes.livingArea! > 0)
            const SizedBox(height: 8),

          if (dvf.attributes.rooms != null && dvf.attributes.rooms! > 0)
            _InfoRow(
              icon: Icons.door_front_door,
              label: 'Pièces',
              value: '${dvf.attributes.rooms}',
            ),
          if (dvf.attributes.rooms != null && dvf.attributes.rooms! > 0)
            const SizedBox(height: 8),

          if (dvf.attributes.landArea != null && dvf.attributes.landArea! > 0)
            _InfoRow(
              icon: Icons.landscape,
              label: 'Terrain',
              value: '${dvf.attributes.landArea!.toStringAsFixed(0)} m²',
            ),
          if (dvf.attributes.landArea != null && dvf.attributes.landArea! > 0)
            const SizedBox(height: 8),

          _InfoRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: _formatDate(dvf.txDate),
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
