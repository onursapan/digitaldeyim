import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/agents/prompter_agent.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/utils/logger.dart';
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
  /// Shotstack render için hazırlanmış timeline JSON.
  /// preparePreview'da üretilir, approveAndRender'da doğrudan kullanılır.
  final Map<String, dynamic>? shotstackJson;

  const StudioState({
    this.phase = StudioPhase.idle,
    this.session,
    this.generatedCaption,
    this.draftVideoPath,
    this.finalVideoUrl,
    this.currentJobId,
    this.errorMessage,
    this.creditsRequired = 1,
    this.shotstackJson,
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
    Map<String, dynamic>? shotstackJson,
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
      shotstackJson: shotstackJson ?? this.shotstackJson,
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

    // 1. Prompter Agent: Gemini prompt + Shotstack timeline JSON oluştur
    //    shotstackJson state'e kaydedilir → approveAndRender'da yeniden kullanılır.
    final prompter = _ref.read(prompterAgentProvider);
    final promptOutput = await prompter.process(
      PrompterInput(userProfile: userProfile, session: session),
    );

    state = state.copyWith(
      phase: StudioPhase.generatingCaption,
      shotstackJson: promptOutput.shotstackJson,
    );

    // 2. Gerçek Gemini API çağrısı — caption üret
    final gemini = _ref.read(geminiServiceProvider);
    final caption = await gemini.generateShotstackPrompt(
      profile: userProfile,
      sector: session.sector,
      clipPaths: session.clips.map((c) => c.localPath).toList(),
    );

    // 3. Draft önizleme yolu — Phase 2'de FFmpeg local render
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

  /// Kullanıcı draft'ı onayladı — cloud render başlat.
  /// preparePreview'da hazırlanan shotstackJson kullanılır (çift çağrı yok).
  Future<void> approveAndRender({
    required ShootSession session,
    required UserProfile userProfile,
  }) async {
    state = state.copyWith(phase: StudioPhase.rendering);

    // State'te kayıtlı JSON yoksa yeniden üret (edge case: rejectDraft sonrası)
    Map<String, dynamic> renderJson;
    if (state.shotstackJson != null) {
      renderJson = state.shotstackJson!;
    } else {
      final prompter = _ref.read(prompterAgentProvider);
      final output = await prompter.process(
        PrompterInput(userProfile: userProfile, session: session),
      );
      renderJson = output.shotstackJson;
    }

    final shotstack = _ref.read(shotstackServiceProvider);
    final jobId = await shotstack.submitRender(renderJson);

    if (jobId == null) {
      // Shotstack API hatası — local simülasyon ile devam et
      final simId = 'local_sim_${DateTime.now().millisecondsSinceEpoch}';
      appLogger.w('[Studio] Shotstack submit failed, falling back to sim: $simId');
      state = state.copyWith(currentJobId: simId);
      _startPolling(simId);
      return;
    }

    state = state.copyWith(currentJobId: jobId);
    _startPolling(jobId);
  }

  /// Mevcut caption'ı yeni bir Gemini isteğiyle yeniden üret.
  Future<void> regenerateCaption({required UserProfile userProfile}) async {
    if (state.session == null) return;

    state = state.copyWith(
      phase: StudioPhase.generatingCaption,
      generatedCaption: null,
    );

    final gemini = _ref.read(geminiServiceProvider);
    final caption = await gemini.generateShotstackPrompt(
      profile: userProfile,
      sector: state.session!.sector,
      clipPaths: state.session!.clips.map((c) => c.localPath).toList(),
    );

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

        // Render tamamlandı → kredit düş (async)
        await _ref.read(userProfileProvider.notifier).deductCredits(1);

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

  /// Draft reddedildi — session korunur, taslak alanlar temizlenir.
  /// Screen bunu yakalar ve preparePreview'ı yeniden tetikler.
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

final studioProvider = StateNotifierProvider<StudioNotifier, StudioState>(
  (ref) => StudioNotifier(ref),
);
