import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/app_theme.dart';

class SettingsService {
  static const _keyTheme = 'theme';
  static const _keyLanguage = 'language';
  static const _keySpeechRate = 'speechRate';
  static const _keyPitch = 'pitch';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      theme: AppTheme.values.byName(
        prefs.getString(_keyTheme) ?? AppTheme.oledDark.name,
      ),
      language: prefs.getString(_keyLanguage) ?? 'en-US',
      speechRate: prefs.getDouble(_keySpeechRate) ?? 0.5,
      pitch: prefs.getDouble(_keyPitch) ?? 1.0,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, settings.theme.name);
    await prefs.setString(_keyLanguage, settings.language);
    await prefs.setDouble(_keySpeechRate, settings.speechRate);
    await prefs.setDouble(_keyPitch, settings.pitch);
  }
}
