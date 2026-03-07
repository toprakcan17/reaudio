import 'package:flutter/material.dart';
import 'models/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const AudiobookApp());
}

const appTheme = AppTheme.oledDark;

class AudiobookApp extends StatelessWidget {
  const AudiobookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audiobook TTS',
      theme: appTheme.themeData,
      home: const HomeScreen(),
    );
  }
}
