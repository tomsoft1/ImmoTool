import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

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
    _minSurfaceController.text = settings.minSurface.toString();
    _maxSurfaceController.text = settings.maxSurface.toString();
    _startDateController.text = settings.startDate?.toString() ?? '';
    _endDateController.text = settings.endDate?.toString() ?? '';
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDateController.text = picked.toString().split(' ')[0];
        } else {
          _endDateController.text = picked.toString().split(' ')[0];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Classes DPE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: [
                    FilterChip(
                      label: const Text('A'),
                      selected: settings.selectedDpeGrades.contains('A'),
                      onSelected: (bool selected) {
                        settings.toggleDpeGrade('A');
                      },
                    ),
                    FilterChip(
                      label: const Text('B'),
                      selected: settings.selectedDpeGrades.contains('B'),
                      onSelected: (bool selected) {
                        settings.toggleDpeGrade('B');
                      },
                    ),
                    FilterChip(
                      label: const Text('C'),
                      selected: settings.selectedDpeGrades.contains('C'),
                      onSelected: (bool selected) {
                        settings.toggleDpeGrade('C');
                      },
                    ),
                    FilterChip(
                      label: const Text('D'),
                      selected: settings.selectedDpeGrades.contains('D'),
                      onSelected: (bool selected) {
                        settings.toggleDpeGrade('D');
                      },
                    ),
                    FilterChip(
                      label: const Text('E'),
                      selected: settings.selectedDpeGrades.contains('E'),
                      onSelected: (bool selected) {
                        settings.toggleDpeGrade('E');
                      },
                    ),
                    FilterChip(
                      label: const Text('F'),
                      selected: settings.selectedDpeGrades.contains('F'),
                      onSelected: (bool selected) {
                        settings.toggleDpeGrade('F');
                      },
                    ),
                    FilterChip(
                      label: const Text('G'),
                      selected: settings.selectedDpeGrades.contains('G'),
                      onSelected: (bool selected) {
                        settings.toggleDpeGrade('G');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Surface du logement (m²)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minSurfaceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Surface minimale',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final number = int.tryParse(value);
                          if (number == null || number < 0) {
                            return 'Veuillez entrer un nombre valide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxSurfaceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Surface maximale',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final number = int.tryParse(value);
                          if (number == null || number < 0) {
                            return 'Veuillez entrer un nombre valide';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Date du DPE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: [
                    FilterChip(
                      label: const Text('3 derniers mois'),
                      selected: settings.dateRange == DateRange.last3Months,
                      onSelected: (bool selected) {
                        if (selected) {
                          settings.setDateRange(DateRange.last3Months);
                        }
                      },
                    ),
                    FilterChip(
                      label: const Text('6 derniers mois'),
                      selected: settings.dateRange == DateRange.last6Months,
                      onSelected: (bool selected) {
                        if (selected) {
                          settings.setDateRange(DateRange.last6Months);
                        }
                      },
                    ),
                    FilterChip(
                      label: const Text('Plage personnalisée'),
                      selected: settings.dateRange == DateRange.custom,
                      onSelected: (bool selected) {
                        if (selected) {
                          settings.setDateRange(DateRange.custom);
                        }
                      },
                    ),
                  ],
                ),
                if (settings.dateRange == DateRange.custom) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startDateController,
                          decoration: const InputDecoration(
                            labelText: 'Date de début',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(context, true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _endDateController,
                          decoration: const InputDecoration(
                            labelText: 'Date de fin',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(context, false),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      settings.updateSettings(
                        minSurface:
                            int.tryParse(_minSurfaceController.text) ?? 0,
                        maxSurface:
                            int.tryParse(_maxSurfaceController.text) ?? 0,
                        startDate: _startDateController.text.isNotEmpty
                            ? DateTime.parse(_startDateController.text)
                            : null,
                        endDate: _endDateController.text.isNotEmpty
                            ? DateTime.parse(_endDateController.text)
                            : null,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Configuration sauvegardée'),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Sauvegarder'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
