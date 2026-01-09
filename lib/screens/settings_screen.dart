import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/immo_colors.dart';
import '../widgets/common/immo_section_card.dart';
import '../widgets/common/dpe_grade_selector.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _minSurfaceController = TextEditingController();
  final _maxSurfaceController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _minSurfaceController.text =
        settings.minSurface > 0 ? settings.minSurface.toString() : '';
    _maxSurfaceController.text =
        settings.maxSurface > 0 ? settings.maxSurface.toString() : '';
    _startDateController.text = settings.startDate != null
        ? _formatDate(settings.startDate!)
        : '';
    _endDateController.text = settings.endDate != null
        ? _formatDate(settings.endDate!)
        : '';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void dispose() {
    _minSurfaceController.dispose();
    _maxSurfaceController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final settings = context.read<SettingsProvider>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (settings.startDate ?? DateTime.now().subtract(const Duration(days: 90)))
          : (settings.endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: ImmoColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDateController.text = _formatDate(picked);
        } else {
          _endDateController.text = _formatDate(picked);
        }
      });
    }
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final settings = context.read<SettingsProvider>();

      DateTime? startDate;
      DateTime? endDate;

      if (_startDateController.text.isNotEmpty) {
        final parts = _startDateController.text.split('/');
        if (parts.length == 3) {
          startDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }

      if (_endDateController.text.isNotEmpty) {
        final parts = _endDateController.text.split('/');
        if (parts.length == 3) {
          endDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }

      settings.updateSettings(
        minSurface: int.tryParse(_minSurfaceController.text) ?? 0,
        maxSurface: int.tryParse(_maxSurfaceController.text) ?? 0,
        startDate: startDate,
        endDate: endDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text('Filtres appliques'),
            ],
          ),
          backgroundColor: ImmoColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Filtres'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // DPE Grades Section
                ImmoSectionCard(
                  title: 'Classes DPE',
                  icon: Icons.energy_savings_leaf,
                  child: DpeGradeSelector(
                    selectedGrades: settings.selectedDpeGrades,
                    onGradeToggle: settings.toggleDpeGrade,
                    onSelectAll: settings.selectAllDpeGrades,
                    onClearAll: settings.clearAllDpeGrades,
                    onSelectPassoires: settings.selectPassoires,
                    onSelectEfficients: settings.selectEfficients,
                  ),
                ),

                const SizedBox(height: 16),

                // Surface Section
                ImmoSectionCard(
                  title: 'Surface',
                  icon: Icons.square_foot,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSurfaceField(
                          controller: _minSurfaceController,
                          label: 'Min',
                          hint: '0',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.arrow_forward,
                          color: ImmoColors.tertiaryLight,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: _buildSurfaceField(
                          controller: _maxSurfaceController,
                          label: 'Max',
                          hint: 'Illimite',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Date Range Section
                ImmoSectionCard(
                  title: 'Periode du DPE',
                  icon: Icons.calendar_month,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDateChip(
                            label: '3 mois',
                            isSelected: settings.dateRange == DateRange.last3Months,
                            onTap: () => settings.setDateRange(DateRange.last3Months),
                          ),
                          _buildDateChip(
                            label: '6 mois',
                            isSelected: settings.dateRange == DateRange.last6Months,
                            onTap: () => settings.setDateRange(DateRange.last6Months),
                          ),
                          _buildDateChip(
                            label: '12 mois',
                            isSelected: settings.dateRange == DateRange.last12Months,
                            onTap: () => settings.setDateRange(DateRange.last12Months),
                          ),
                          _buildDateChip(
                            label: 'Personnalise',
                            icon: Icons.edit_calendar,
                            isSelected: settings.dateRange == DateRange.custom,
                            onTap: () => settings.setDateRange(DateRange.custom),
                          ),
                        ],
                      ),

                      // Custom date pickers
                      if (settings.dateRange == DateRange.custom) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                controller: _startDateController,
                                label: 'Debut',
                                onTap: () => _selectDate(context, true),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(
                                Icons.arrow_forward,
                                color: ImmoColors.tertiaryLight,
                                size: 20,
                              ),
                            ),
                            Expanded(
                              child: _buildDateField(
                                controller: _endDateController,
                                label: 'Fin',
                                onTap: () => _selectDate(context, false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Appearance Section
                ImmoSectionCard(
                  title: 'Apparence',
                  icon: Icons.palette_outlined,
                  child: _buildThemeSelector(settings),
                ),

                const SizedBox(height: 32),

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.check),
                    label: const Text('Appliquer les filtres'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ImmoColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSurfaceField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: 'm\u00b2',
        suffixStyle: TextStyle(
          color: ImmoColors.tertiaryLight,
          fontWeight: FontWeight.w500,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        final number = int.tryParse(value);
        if (number == null || number < 0) {
          return 'Nombre invalide';
        }
        return null;
      },
    );
  }

  Widget _buildDateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? ImmoColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? ImmoColors.primary : ImmoColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? ImmoColors.primary : ImmoColors.tertiaryLight,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? ImmoColors.primary : ImmoColors.tertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'JJ/MM/AAAA',
        suffixIcon: Icon(
          Icons.calendar_today,
          size: 20,
          color: ImmoColors.primary,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(SettingsProvider settings) {
    return Row(
      children: [
        Expanded(
          child: _ThemeOption(
            icon: Icons.light_mode,
            label: 'Clair',
            isSelected: settings.themeMode == ThemeMode.light,
            onTap: () => settings.setThemeMode(ThemeMode.light),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ThemeOption(
            icon: Icons.dark_mode,
            label: 'Sombre',
            isSelected: settings.themeMode == ThemeMode.dark,
            onTap: () => settings.setThemeMode(ThemeMode.dark),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ThemeOption(
            icon: Icons.settings_brightness,
            label: 'Auto',
            isSelected: settings.themeMode == ThemeMode.system,
            onTap: () => settings.setThemeMode(ThemeMode.system),
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? ImmoColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? ImmoColors.primary : ImmoColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? ImmoColors.primary : ImmoColors.tertiaryLight,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? ImmoColors.primary : ImmoColors.tertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
