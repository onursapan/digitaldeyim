import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/agents/validator_agent.dart';
import '../../../core/providers/core_providers.dart';
import '../../../domain/entities/sector.dart';
import '../../../domain/entities/shoot_session.dart';
import 'package:uuid/uuid.dart';

class DirectorState {
  final ShootSession? session;
  final int currentStepIndex;
  final bool isRecording;
  final bool isValidating;
  final LiveValidationFeedback? liveFeedback;
  final String? errorMessage;

  const DirectorState({
    this.session,
    this.currentStepIndex = 0,
    this.isRecording = false,
    this.isValidating = false,
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

  /// Mevcut adımın klibinin validate edilip edilmediğini döner.
  /// "Sonraki Klip" butonunu göstermek için kullanılır.
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
    LiveValidationFeedback? liveFeedback,
    String? errorMessage,
  }) {
    return DirectorState(
      session: session ?? this.session,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isRecording: isRecording ?? this.isRecording,
      isValidating: isValidating ?? this.isValidating,
      liveFeedback: liveFeedback ?? this.liveFeedback,
      errorMessage: errorMessage,
    );
  }
}

class DirectorNotifier extends StateNotifier<DirectorState> {
  final Ref _ref;
  static const _uuid = Uuid();

  // A4 FIX: Subscription saklanıyor, dispose()'da iptal ediliyor.
  StreamSubscription<LiveValidationFeedback>? _liveValidationSub;

  DirectorNotifier(this._ref) : super(const DirectorState()) {
    _listenToValidatorFeedback();
  }

  void _listenToValidatorFeedback() {
    final validator = _ref.read(validatorAgentProvider);
    // A4 FIX: Subscription referansı sakla.
    _liveValidationSub = validator.liveValidation.listen((feedback) {
      // mounted guard: dispose sonrası state update'i önle.
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

  void startRecording() => state = state.copyWith(isRecording: true);

  Future<void> stopRecordingAndValidate(String videoPath) async {
    state = state.copyWith(isRecording: false, isValidating: true);

    final validator = _ref.read(validatorAgentProvider);
    final currentStep = state.currentStep;
    if (currentStep == null || state.session == null) return;

    final result = await validator.process(ValidatorInput(
      videoPath: videoPath,
      checklist: state.session!.sector.directorBrief.checklist,
    ));

    final newClip = ShootClip(
      stepId: currentStep.id,
      localPath: videoPath,
      status: result.isValid ? ClipStatus.validated : ClipStatus.rejected,
      validationResult: result,
    );

    final updatedClips = [...state.session!.clips, newClip];
    final updatedSession = state.session!.copyWith(clips: updatedClips);

    state = state.copyWith(
      session: updatedSession,
      isValidating: false,
      errorMessage: result.isValid ? null : result.warningMessage,
    );
  }

  /// A1 FIX: Rejected clip'i listeden siler.
  /// Önceki implementasyon yalnızca errorMessage'ı temizliyordu;
  /// rejected clip listede kalınca isReadyForDraft kalıcı false oluyordu.
  void retakeCurrentClip() {
    final step = state.currentStep;
    if (step == null || state.session == null) {
      state = state.copyWith(errorMessage: null, isRecording: false);
      return;
    }

    // Mevcut adıma ait rejected clip'i filtrele.
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
    // A4 FIX: Memory leak'i önle — subscription iptal et.
    _liveValidationSub?.cancel();
    super.dispose();
  }
}

final directorProvider =
    StateNotifierProvider<DirectorNotifier, DirectorState>(
  (ref) => DirectorNotifier(ref),
);
