import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;

  static const _languages = [
    ('en-US', 'English (US)'),
    ('en-GB', 'English (UK)'),
    ('tr-TR', 'Turkish'),
    ('de-DE', 'German'),
    ('fr-FR', 'French'),
    ('es-ES', 'Spanish'),
    ('it-IT', 'Italian'),
    ('pt-BR', 'Portuguese (Brazil)'),
    ('ja-JP', 'Japanese'),
    ('ko-KR', 'Korean'),
    ('zh-CN', 'Chinese (Simplified)'),
  ];

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _update(AppSettings updated) {
    setState(() => _settings = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            trailing: DropdownButton<AppTheme>(
              value: _settings.theme,
              underline: const SizedBox.shrink(),
              onChanged: (v) {
                if (v != null) _update(_settings.copyWith(theme: v));
              },
              items: AppTheme.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
            ),
          ),
          const Divider(),
          _SectionHeader(title: 'Text-to-Speech'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: _settings.language,
              underline: const SizedBox.shrink(),
              onChanged: (v) {
                if (v != null) _update(_settings.copyWith(language: v));
              },
              items: _languages
                  .map((l) => DropdownMenuItem(value: l.$1, child: Text(l.$2)))
                  .toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Speech Rate'),
            subtitle: Slider(
              value: _settings.speechRate,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: _settings.speechRate.toStringAsFixed(1),
              onChanged: (v) => _update(_settings.copyWith(speechRate: v)),
            ),
            trailing: Text(_settings.speechRate.toStringAsFixed(1)),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Pitch'),
            subtitle: Slider(
              value: _settings.pitch,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: _settings.pitch.toStringAsFixed(1),
              onChanged: (v) => _update(_settings.copyWith(pitch: v)),
            ),
            trailing: Text(_settings.pitch.toStringAsFixed(1)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, _settings),
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
