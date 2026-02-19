import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

class TtsService {
  final FlutterTts _tts = FlutterTts();
  final Logger _log = Logger();
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(0.45); // Doğal konuşma hızı
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _isInitialized = true;
  }

  /// Metni sesli olarak okur.
  Future<void> speak(String text) async {
    try {
      await _ensureInitialized();
      await _tts.stop();
      await _tts.speak(text);
      _log.d('[TTS] Speaking: ${text.substring(0, text.length.clamp(0, 50))}');
    } catch (e) {
      _log.w('[TTS] Speak failed: $e');
    }
  }

  /// Devam eden sesi durdurur.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      _log.w('[TTS] Stop failed: $e');
    }
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
