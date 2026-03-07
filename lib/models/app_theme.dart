import 'package:flutter/material.dart';

enum AppTheme {
  light,
  dark,
  oledDark;

  String get label => switch (this) {
        AppTheme.light => 'Light',
        AppTheme.dark => 'Dark',
        AppTheme.oledDark => 'OLED Dark',
      };

  ThemeData get themeData => switch (this) {
        AppTheme.light => ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            useMaterial3: true,
          ),
        AppTheme.dark => ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
        AppTheme.oledDark => ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.dark,
            ).copyWith(
              surface: Colors.black,
            ),
            scaffoldBackgroundColor: Colors.black,
            useMaterial3: true,
          ),
      };
}
