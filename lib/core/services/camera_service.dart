import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

final cameraServiceProvider =
    Provider<CameraService>((ref) => CameraService());

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  final Logger _log = Logger();

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isRecording => _controller?.value.isRecordingVideo ?? false;

  /// Mevcut kameraları listeler ve arka kamerayla controller başlatır.
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('no_cameras', 'No cameras available on device');
      }

      // Arka kamera tercih edilir
      final back = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _log.i('Camera initialized: ${back.name}');
    } on CameraException catch (e) {
      _log.e('CameraException on initialize: ${e.code} — ${e.description}');
      rethrow;
    }
  }

  /// Video kaydını başlatır.
  Future<void> startRecording() async {
    if (_controller == null || !isInitialized) {
      throw CameraException('not_initialized', 'Camera is not initialized');
    }
    if (isRecording) return;

    try {
      await _controller!.startVideoRecording();
      _log.i('Recording started');
    } on CameraException catch (e) {
      _log.e('CameraException on startRecording: ${e.code}');
      rethrow;
    }
  }

  /// Video kaydını durdurur ve dosya yolunu döner.
  Future<String> stopRecording() async {
    if (_controller == null || !isRecording) {
      throw CameraException('not_recording', 'No active recording');
    }

    try {
      final xfile = await _controller!.stopVideoRecording();
      _log.i('Recording stopped: ${xfile.path}');
      return xfile.path;
    } on CameraException catch (e) {
      _log.e('CameraException on stopRecording: ${e.code}');
      rethrow;
    }
  }

  /// Fotoğraf çeker ve dosya yolunu döner.
  Future<String> takePicture() async {
    if (_controller == null || !isInitialized) {
      throw CameraException('not_initialized', 'Camera is not initialized');
    }

    try {
      final xfile = await _controller!.takePicture();
      _log.i('Picture taken: ${xfile.path}');
      return xfile.path;
    } on CameraException catch (e) {
      _log.e('CameraException on takePicture: ${e.code}');
      rethrow;
    }
  }

  /// Kamerayı serbest bırakır — Director ekranı dispose'da çağırır.
  Future<void> dispose() async {
    try {
      await _controller?.dispose();
      _controller = null;
      _log.i('Camera disposed');
    } catch (e) {
      _log.w('Error disposing camera: $e');
    }
  }
}

/// Ses kaydı için ayrı bir path üretir.
Future<String> buildAudioPath() async {
  final dir = await getTemporaryDirectory();
  final filename = '${DateTime.now().millisecondsSinceEpoch}.m4a';
  return p.join(dir.path, filename);
}
