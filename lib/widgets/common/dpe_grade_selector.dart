import 'package:flutter/material.dart';
import '../../theme/immo_colors.dart';

/// Visual DPE grade selector widget
///
/// Displays DPE grades A-G as colored chips with selection state.
/// Includes quick-select buttons for common filter presets.
class DpeGradeSelector extends StatelessWidget {
  final Set<String> selectedGrades;
  final ValueChanged<String> onGradeToggle;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearAll;
  final VoidCallback? onSelectPassoires;
  final VoidCallback? onSelectEfficients;

  const DpeGradeSelector({
    super.key,
    required this.selectedGrades,
    required this.onGradeToggle,
    this.onSelectAll,
    this.onClearAll,
    this.onSelectPassoires,
    this.onSelectEfficients,
  });

  static const List<String> grades = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grade chips
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: grades.map((grade) {
            final isSelected = selectedGrades.contains(grade);
            final color = ImmoColors.getDpeColor(grade);

            return _DpeGradeChip(
              grade: grade,
              color: color,
              isSelected: isSelected,
              onTap: () => onGradeToggle(grade),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Quick select buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickSelectButton(
              label: 'Tous',
              icon: Icons.select_all,
              onTap: onSelectAll,
            ),
            _QuickSelectButton(
              label: 'Aucun',
              icon: Icons.deselect,
              onTap: onClearAll,
            ),
            _QuickSelectButton(
              label: 'Passoires (F-G)',
              icon: Icons.warning_amber_rounded,
              color: ImmoColors.error,
              onTap: onSelectPassoires,
            ),
            _QuickSelectButton(
              label: 'Efficients (A-C)',
              icon: Icons.eco,
              color: ImmoColors.success,
              onTap: onSelectEfficients,
            ),
          ],
        ),
      ],
    );
  }
}

class _DpeGradeChip extends StatelessWidget {
  final String grade;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _DpeGradeChip({
    required this.grade,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = ImmoColors.getDpeTextColor(grade);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            grade,
            style: TextStyle(
              color: isSelected ? textColor : color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickSelectButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const _QuickSelectButton({
    required this.label,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? ImmoColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: buttonColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: buttonColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: buttonColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: buttonColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
