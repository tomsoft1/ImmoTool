import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/property_map_screen.dart';
import 'providers/settings_provider.dart';
import 'theme/immo_theme.dart';

void main() {
  runApp(const ImmoToolApp());
}

class ImmoToolApp extends StatelessWidget {
  const ImmoToolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'ImmoTool',
            debugShowCheckedModeBanner: false,
            theme: ImmoTheme.lightTheme,
            darkTheme: ImmoTheme.darkTheme,
            themeMode: settings.themeMode,
            home: const PropertyMapScreen(),
          );
        },
      ),
    );
  }
}
