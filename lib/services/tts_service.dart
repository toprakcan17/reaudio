import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  VoidCallback? onComplete;

  TtsService() {
    _tts.setLanguage('en-US');
    _tts.setPitch(1.0);
    _tts.setSpeechRate(0.5);
    _tts.setCompletionHandler(() {
      onComplete?.call();
    });
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}

typedef VoidCallback = void Function();
