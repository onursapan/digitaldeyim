import 'dart:async';
import 'dart:isolate';
import '../../domain/entities/sector.dart';
import '../../domain/entities/shoot_session.dart';
import '../utils/logger.dart';
import 'base_agent.dart';

class ValidatorInput {
  final String videoPath;
  final CameraChecklist checklist;

  const ValidatorInput({required this.videoPath, required this.checklist});
}

/// Validator Agent — çekim kalitesini denetler.
/// Ağır CV işlemleri Isolate'te çalışır, main thread bloklanmaz.
class ValidatorAgent extends BaseAgent<ValidatorInput, ValidationResult> {
  @override
  String get agentName => 'ValidatorAgent';

  // Anlık kamera stream'i için — Director Mode'da çalışır
  final _liveValidationController =
      StreamController<LiveValidationFeedback>.broadcast();

  Stream<LiveValidationFeedback> get liveValidation =>
      _liveValidationController.stream;

  /// Gerçek zamanlı sensör verilerini işler (CameraController callback'inden gelir)
  void processLiveFrame({
    required double luxValue,
    required double shakeValue,
    required CameraChecklist checklist,
  }) {
    final lightOk = luxValue >= checklist.minLux;
    final stableOk = shakeValue <= checklist.maxShake;

    _liveValidationController.add(LiveValidationFeedback(
      lightingOk: lightOk,
      stabilityOk: stableOk,
      luxValue: luxValue,
      shakeValue: shakeValue,
      lightingMessage: lightOk ? null : checklist.lightingTip,
    ));
  }

  /// Kaydedilen videonun son validasyonu — Isolate'te çalışır
  @override
  Future<ValidationResult> process(ValidatorInput input) async {
    emitProcessing();
    log('Validating: ${input.videoPath}');

    try {
      final result = await _validateInIsolate(input);
      if (result.isValid) {
        emitSuccess();
      } else {
        emitFailure(result.warningMessage ?? 'Kalite kontrolü başarısız.');
      }
      return result;
    } catch (e) {
      logError('Validation error', e);
      emitFailure('Doğrulama sırasında hata oluştu.');
      return const ValidationResult(
        lightingOk: false,
        stabilityOk: false,
        durationOk: false,
        warningMessage: 'Doğrulama başarısız.',
      );
    }
  }

  Future<ValidationResult> _validateInIsolate(ValidatorInput input) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _validationWorker,
      _IsolateMessage(
        sendPort: receivePort.sendPort,
        videoPath: input.videoPath,
        minLux: input.checklist.minLux,
        maxShake: input.checklist.maxShake,
      ),
    );
    return await receivePort.first as ValidationResult;
  }

  @override
  void dispose() {
    _liveValidationController.close();
    super.dispose();
  }
}

// Isolate'te çalışan worker — UI thread'den bağımsız
void _validationWorker(_IsolateMessage message) {
  // Faz 1: Simüle edilmiş validasyon
  // Gerçek implementasyonda ML Kit / MediaPipe buraya entegre edilir
  final result = _simulateValidation(message);
  message.sendPort.send(result);
}

ValidationResult _simulateValidation(_IsolateMessage msg) {
  // TODO: Gerçek video metadata analizi (ML Kit entegrasyonu)
  // Şimdilik: dosya var ve geçerli path ise onay ver
  final fileExists = msg.videoPath.isNotEmpty;
  return ValidationResult(
    lightingOk: fileExists,
    stabilityOk: fileExists,
    durationOk: fileExists,
    warningMessage: fileExists ? null : 'Video dosyası bulunamadı.',
  );
}

class _IsolateMessage {
  final SendPort sendPort;
  final String videoPath;
  final double minLux;
  final double maxShake;

  const _IsolateMessage({
    required this.sendPort,
    required this.videoPath,
    required this.minLux,
    required this.maxShake,
  });
}

class LiveValidationFeedback {
  final bool lightingOk;
  final bool stabilityOk;
  final double luxValue;
  final double shakeValue;
  final String? lightingMessage;

  const LiveValidationFeedback({
    required this.lightingOk,
    required this.stabilityOk,
    required this.luxValue,
    required this.shakeValue,
    this.lightingMessage,
  });

  bool get allOk => lightingOk && stabilityOk;
}
