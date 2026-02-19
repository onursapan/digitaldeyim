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

  bool get allClipsValidated =>
      session?.isReadyForDraft ?? false;

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

  DirectorNotifier(this._ref) : super(const DirectorState()) {
    _listenToValidatorFeedback();
  }

  void _listenToValidatorFeedback() {
    final validator = _ref.read(validatorAgentProvider);
    validator.liveValidation.listen((feedback) {
      state = state.copyWith(liveFeedback: feedback);
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

  void retakeCurrentClip() {
    state = state.copyWith(errorMessage: null, isRecording: false);
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
}

final directorProvider =
    StateNotifierProvider<DirectorNotifier, DirectorState>(
  (ref) => DirectorNotifier(ref),
);
