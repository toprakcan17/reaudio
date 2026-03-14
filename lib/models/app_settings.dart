import 'app_theme.dart';

class AppSettings {
  final AppTheme theme;
  final String language;
  final double speechRate;
  final double pitch;

  const AppSettings({
    this.theme = AppTheme.oledDark,
    this.language = 'en-US',
    this.speechRate = 0.5,
    this.pitch = 1.0,
  });

  AppSettings copyWith({
    AppTheme? theme,
    String? language,
    double? speechRate,
    double? pitch,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
    );
  }
}
