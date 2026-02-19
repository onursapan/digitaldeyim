import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

final microphoneServiceProvider =
    Provider<MicrophoneService>((ref) => MicrophoneService());

class MicrophoneService {
  final AudioRecorder _recorder = AudioRecorder();
  final Logger _log = Logger();
  String? _currentPath;

  bool get isRecording => _currentPath != null;

  /// Ses kaydını başlatır. Dosya path'ini döner.
  Future<String> startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission denied');
      }

      final dir = await getTemporaryDirectory();
      final filename = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentPath = p.join(dir.path, filename);

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentPath!,
      );

      _log.i('Microphone recording started: $_currentPath');
      return _currentPath!;
    } catch (e) {
      _log.e('Failed to start recording: $e');
      _currentPath = null;
      rethrow;
    }
  }

  /// Ses kaydını durdurur ve kaydedilen dosyanın path'ini döner.
  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _log.i('Microphone recording stopped: $path');
      _currentPath = null;
      return path;
    } catch (e) {
      _log.e('Failed to stop recording: $e');
      _currentPath = null;
      rethrow;
    }
  }

  /// Kaydı iptal eder.
  Future<void> cancelRecording() async {
    try {
      await _recorder.cancel();
      _currentPath = null;
      _log.i('Microphone recording cancelled');
    } catch (e) {
      _log.w('Failed to cancel recording: $e');
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
