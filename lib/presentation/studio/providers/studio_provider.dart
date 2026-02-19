import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/agents/prompter_agent.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../data/repositories/shotstack_service.dart';
import '../../../domain/entities/shoot_session.dart';
import '../../../domain/entities/user_profile.dart';

enum StudioPhase {
  idle,
  buildingPrompt,
  generatingCaption,
  draftReady,
  awaitingApproval,
  rendering,
  completed,
  failed,
}

class StudioState {
  final StudioPhase phase;
  final ShootSession? session;
  final String? generatedCaption;
  final String? draftVideoPath;
  final String? finalVideoUrl;
  final String? currentJobId;
  final String? errorMessage;
  final int creditsRequired;

  const StudioState({
    this.phase = StudioPhase.idle,
    this.session,
    this.generatedCaption,
    this.draftVideoPath,
    this.finalVideoUrl,
    this.currentJobId,
    this.errorMessage,
    this.creditsRequired = 1,
  });

  bool get canRequestRender => phase == StudioPhase.awaitingApproval;

  StudioState copyWith({
    StudioPhase? phase,
    ShootSession? session,
    String? generatedCaption,
    String? draftVideoPath,
    String? finalVideoUrl,
    String? currentJobId,
    String? errorMessage,
    int? creditsRequired,
  }) {
    return StudioState(
      phase: phase ?? this.phase,
      session: session ?? this.session,
      generatedCaption: generatedCaption ?? this.generatedCaption,
      draftVideoPath: draftVideoPath ?? this.draftVideoPath,
      finalVideoUrl: finalVideoUrl ?? this.finalVideoUrl,
      currentJobId: currentJobId ?? this.currentJobId,
      errorMessage: errorMessage,
      creditsRequired: creditsRequired ?? this.creditsRequired,
    );
  }
}

class StudioNotifier extends StateNotifier<StudioState> {
  final Ref _ref;
  Timer? _pollingTimer;

  StudioNotifier(this._ref) : super(const StudioState());

  Future<void> preparePreview({
    required ShootSession session,
    required UserProfile userProfile,
  }) async {
    state = state.copyWith(phase: StudioPhase.buildingPrompt, session: session);

    // 1. Prompter Agent: JSON + Gemini prompt oluştur
    final prompter = _ref.read(prompterAgentProvider);
    final promptOutput = await prompter.process(
      PrompterInput(userProfile: userProfile, session: session),
    );

    state = state.copyWith(phase: StudioPhase.generatingCaption);

    // 2. Gemini: Açıklama metni üret
    final gemini = _ref.read(geminiServiceProvider);
    final caption = await gemini.generateCaption(promptOutput.geminiPrompt);

    // 3. Local draft simülasyonu (Faz 1)
    // Faz 2'de gerçek FFmpeg lokal render buraya gelir
    await Future.delayed(const Duration(seconds: 1));
    const draftPath = 'local://draft_simulation.mp4';

    state = state.copyWith(
      phase: StudioPhase.draftReady,
      generatedCaption: caption,
      draftVideoPath: draftPath,
    );

    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(phase: StudioPhase.awaitingApproval);
  }

  /// Kullanıcı draft'ı onayladı — cloud render başlat
  Future<void> approveAndRender({
    required ShootSession session,
    required UserProfile userProfile,
  }) async {
    state = state.copyWith(phase: StudioPhase.rendering);

    final prompter = _ref.read(prompterAgentProvider);
    final promptOutput = await prompter.process(
      PrompterInput(userProfile: userProfile, session: session),
    );

    final shotstack = _ref.read(shotstackServiceProvider);
    final jobId = await shotstack.submitRender(promptOutput.shotstackJson);

    state = state.copyWith(currentJobId: jobId);
    _startPolling(jobId);
  }

  /// B2: Mevcut caption'ı yeni bir Gemini isteğiyle yeniden üret.
  Future<void> regenerateCaption({required UserProfile userProfile}) async {
    if (state.session == null) return;

    // Spinner göster, eski caption'ı temizle
    state = state.copyWith(
      phase: StudioPhase.generatingCaption,
      generatedCaption: null,
    );

    final prompter = _ref.read(prompterAgentProvider);
    final out = await prompter.process(
      PrompterInput(userProfile: userProfile, session: state.session!),
    );

    final gemini = _ref.read(geminiServiceProvider);
    final caption = await gemini.generateCaption(out.geminiPrompt);

    state = state.copyWith(
      phase: StudioPhase.awaitingApproval,
      generatedCaption: caption,
    );
  }

  void _startPolling(String jobId) {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final shotstack = _ref.read(shotstackServiceProvider);
      final job = await shotstack.checkStatus(jobId);

      if (job.status == RenderStatus.done) {
        _pollingTimer?.cancel();

        // B1: Render tamamlandı → kredit düş
        _ref.read(userProfileProvider.notifier).deductCredits(1);

        state = state.copyWith(
          phase: StudioPhase.completed,
          finalVideoUrl: job.videoUrl,
        );
      } else if (job.status == RenderStatus.failed) {
        _pollingTimer?.cancel();
        state = state.copyWith(
          phase: StudioPhase.failed,
          errorMessage: 'Render başarısız oldu. Lütfen tekrar deneyin.',
        );
      }
    });
  }

  /// A3 FIX: rejectDraft session'ı korur, sadece taslak alanlarını temizler.
  /// Screen bunu yakaladığında preparePreview'ı yeniden tetikler.
  void rejectDraft() {
    state = state.copyWith(
      phase: StudioPhase.idle,
      draftVideoPath: null,
      generatedCaption: null,
      errorMessage: null,
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final studioProvider =
    StateNotifierProvider<StudioNotifier, StudioState>(
  (ref) => StudioNotifier(ref),
);
