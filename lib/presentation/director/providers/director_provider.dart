import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/agents/validator_agent.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../domain/entities/sector.dart';
import '../../../domain/entities/shoot_session.dart';

class DirectorState {
  final ShootSession? session;
  final int currentStepIndex;
  final bool isRecording;
  final bool isValidating;
  final bool isUploading;
  final LiveValidationFeedback? liveFeedback;
  final String? errorMessage;

  const DirectorState({
    this.session,
    this.currentStepIndex = 0,
    this.isRecording = false,
    this.isValidating = false,
    this.isUploading = false,
    this.liveFeedback,
    this.errorMessage,
  });

  ShootStep? get currentStep {
    final steps = session?.sector.directorBrief.steps;
    if (steps == null || currentStepIndex >= steps.length) return null;
    return steps[currentStepIndex];
  }

  bool get isLastStep {
    final steps = session?.sector.directorBrief.steps;
    if (steps == null) return false;
    return currentStepIndex == steps.length - 1;
  }

  bool get allClipsValidated => session?.isReadyForDraft ?? false;

  bool get currentClipValidated {
    final step = currentStep;
    if (step == null || session == null) return false;
    return session!.clips.any(
      (c) => c.stepId == step.id && c.status == ClipStatus.validated,
    );
  }

  DirectorState copyWith({
    ShootSession? session,
    int? currentStepIndex,
    bool? isRecording,
    bool? isValidating,
    bool? isUploading,
    LiveValidationFeedback? liveFeedback,
    String? errorMessage,
  }) {
    return DirectorState(
      session: session ?? this.session,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isRecording: isRecording ?? this.isRecording,
      isValidating: isValidating ?? this.isValidating,
      isUploading: isUploading ?? this.isUploading,
      liveFeedback: liveFeedback ?? this.liveFeedback,
      errorMessage: errorMessage,
    );
  }
}

class DirectorNotifier extends StateNotifier<DirectorState> {
  final Ref _ref;
  static const _uuid = Uuid();

  StreamSubscription<LiveValidationFeedback>? _liveValidationSub;

  DirectorNotifier(this._ref) : super(const DirectorState()) {
    _listenToValidatorFeedback();
  }

  CameraService get _camera => _ref.read(cameraServiceProvider);
  StorageService get _storage => _ref.read(storageServiceProvider);

  void _listenToValidatorFeedback() {
    final validator = _ref.read(validatorAgentProvider);
    _liveValidationSub = validator.liveValidation.listen((feedback) {
      if (mounted) state = state.copyWith(liveFeedback: feedback);
    });
  }

  void initSession({required Sector sector, required String userId}) {
    final session = ShootSession(
      id: _uuid.v4(),
      userId: userId,
      sector: sector,
      clips: [],
      status: SessionStatus.shooting,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(session: session, currentStepIndex: 0);
  }

  /// Gerçek kamera ile video kaydını başlatır.
  Future<void> startRecording() async {
    try {
      await _camera.startRecording();
      state = state.copyWith(isRecording: true, errorMessage: null);
    } on Exception catch (e) {
      state = state.copyWith(
        isRecording: false,
        errorMessage: 'Kamera başlatılamadı: $e',
      );
    }
  }

  /// Video kaydını durdurur, Validator'a gönderir, Storage'a yükler.
  Future<void> stopRecordingAndValidate() async {
    state = state.copyWith(isRecording: false, isValidating: true);

    final currentStep = state.currentStep;
    if (currentStep == null || state.session == null) return;

    try {
      // 1. Kaydı durdur — gerçek dosya yolu al
      final videoPath = await _camera.stopRecording();

      // 2. Validator'a gönder
      final validator = _ref.read(validatorAgentProvider);
      final result = await validator.process(ValidatorInput(
        videoPath: videoPath,
        checklist: state.session!.sector.directorBrief.checklist,
      ));

      // 3. Storage'a yükle (arka planda, UI'yi bloke etmeden)
      String uploadedPath = videoPath;
      if (result.isValid) {
        state = state.copyWith(isValidating: false, isUploading: true);
        final uid = _ref.read(authServiceProvider).currentUser?.uid ?? 'anon';
        try {
          uploadedPath = await _storage.uploadClip(
            uid: uid,
            sessionId: state.session!.id,
            stepId: currentStep.id,
            file: File(videoPath),
          );
        } catch (e) {
          // Upload başarısız olsa bile local path ile devam et
          uploadedPath = videoPath;
        }
      }

      final newClip = ShootClip(
        stepId: currentStep.id,
        localPath: uploadedPath,
        status: result.isValid ? ClipStatus.validated : ClipStatus.rejected,
        validationResult: result,
      );

      final updatedClips = [...state.session!.clips, newClip];
      final updatedSession = state.session!.copyWith(clips: updatedClips);

      state = state.copyWith(
        session: updatedSession,
        isValidating: false,
        isUploading: false,
        errorMessage: result.isValid ? null : result.warningMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isValidating: false,
        isUploading: false,
        errorMessage: 'Kayıt işlenemedi: $e',
      );
    }
  }

  void retakeCurrentClip() {
    final step = state.currentStep;
    if (step == null || state.session == null) {
      state = state.copyWith(errorMessage: null, isRecording: false);
      return;
    }

    final filteredClips = state.session!.clips
        .where((c) => c.stepId != step.id)
        .toList();

    final updatedSession = state.session!.copyWith(clips: filteredClips);

    state = state.copyWith(
      session: updatedSession,
      errorMessage: null,
      isRecording: false,
    );
  }

  void nextStep() {
    if (!state.isLastStep) {
      state = state.copyWith(
        currentStepIndex: state.currentStepIndex + 1,
        errorMessage: null,
      );
    }
  }

  void updateLiveFeedback({required double lux, required double shake}) {
    final validator = _ref.read(validatorAgentProvider);
    final checklist = state.session?.sector.directorBrief.checklist;
    if (checklist != null) {
      validator.processLiveFrame(
        luxValue: lux,
        shakeValue: shake,
        checklist: checklist,
      );
    }
  }

  @override
  void dispose() {
    _liveValidationSub?.cancel();
    _camera.dispose();
    super.dispose();
  }
}

final directorProvider =
    StateNotifierProvider<DirectorNotifier, DirectorState>(
  (ref) => DirectorNotifier(ref),
);
