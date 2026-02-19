import 'package:equatable/equatable.dart';
import 'sector.dart';

/// Bir çekim oturumunun tam yaşam döngüsünü temsil eder.
class ShootSession extends Equatable {
  final String id;
  final String userId;
  final Sector sector;
  final List<ShootClip> clips;
  final SessionStatus status;
  final String? draftVideoPath; // Local preview dosya yolu
  final String? finalVideoUrl;  // Cloud render sonucu
  final DateTime createdAt;

  const ShootSession({
    required this.id,
    required this.userId,
    required this.sector,
    required this.clips,
    required this.status,
    this.draftVideoPath,
    this.finalVideoUrl,
    required this.createdAt,
  });

  bool get isReadyForDraft =>
      clips.every((c) => c.status == ClipStatus.validated);
  bool get isReadyForRender =>
      status == SessionStatus.draftApproved;

  ShootSession copyWith({
    List<ShootClip>? clips,
    SessionStatus? status,
    String? draftVideoPath,
    String? finalVideoUrl,
  }) {
    return ShootSession(
      id: id,
      userId: userId,
      sector: sector,
      clips: clips ?? this.clips,
      status: status ?? this.status,
      draftVideoPath: draftVideoPath ?? this.draftVideoPath,
      finalVideoUrl: finalVideoUrl ?? this.finalVideoUrl,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, status];
}

class ShootClip extends Equatable {
  final String stepId;
  final String localPath;
  final ClipStatus status;
  final ValidationResult? validationResult;

  const ShootClip({
    required this.stepId,
    required this.localPath,
    required this.status,
    this.validationResult,
  });

  @override
  List<Object?> get props => [stepId, localPath, status];
}

class ValidationResult extends Equatable {
  final bool lightingOk;
  final bool stabilityOk;
  final bool durationOk;
  final String? warningMessage;

  const ValidationResult({
    required this.lightingOk,
    required this.stabilityOk,
    required this.durationOk,
    this.warningMessage,
  });

  bool get isValid => lightingOk && stabilityOk && durationOk;

  @override
  List<Object?> get props => [lightingOk, stabilityOk, durationOk];
}

enum SessionStatus {
  shooting,
  validating,
  draftReady,
  draftApproved,
  rendering,
  completed,
  failed,
}

enum ClipStatus {
  recording,
  recorded,
  validating,
  validated,
  rejected,
}
