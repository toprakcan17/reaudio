import 'package:flutter/material.dart';
import 'models/app_settings.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';

void main() {
  runApp(const AudiobookApp());
}

class AudiobookApp extends StatefulWidget {
  const AudiobookApp({super.key});

  static _AudiobookAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_AudiobookAppState>()!;

  @override
  State<AudiobookApp> createState() => _AudiobookAppState();
}

class _AudiobookAppState extends State<AudiobookApp> {
  final SettingsService _settingsService = SettingsService();
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.load();
    setState(() => _settings = settings);
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _settingsService.save(settings);
    setState(() => _settings = settings);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audiobook TTS',
      theme: _settings.theme.themeData,
      home: const HomeScreen(),
    );
  }
}
