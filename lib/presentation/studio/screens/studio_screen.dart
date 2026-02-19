import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../providers/studio_provider.dart';
import '../../director/providers/director_provider.dart';
import '../../../core/extensions/l10n_extension.dart';

class StudioScreen extends ConsumerStatefulWidget {
  const StudioScreen({super.key});

  @override
  ConsumerState<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends ConsumerState<StudioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPreview());
  }

  void _startPreview() {
    final directorState = ref.read(directorProvider);
    final profile = ref.read(userProfileProvider);
    if (directorState.session == null || profile == null) return;

    ref.read(studioProvider.notifier).preparePreview(
          session: directorState.session!,
          userProfile: profile,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studioProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.studioAppBarTitle),
        actions: [
          if (state.phase == StudioPhase.awaitingApproval)
            TextButton(
              // A3 FIX: rejectDraft + postFrameCallback ile preparePreview yeniden tetikle.
              onPressed: () {
                ref.read(studioProvider.notifier).rejectDraft();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final session = ref.read(directorProvider).session;
                  final profile = ref.read(userProfileProvider);
                  if (session != null && profile != null) {
                    ref.read(studioProvider.notifier).preparePreview(
                          session: session,
                          userProfile: profile,
                        );
                  }
                });
              },
              child: Text(
                context.l10n.studioRejectButton,
                style: const TextStyle(color: Color(0xFFE53E3E)),
              ),
            ),
        ],
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(StudioState state, ThemeData theme) {
    return switch (state.phase) {
      StudioPhase.idle ||
      StudioPhase.buildingPrompt ||
      StudioPhase.generatingCaption =>
        _LoadingView(phase: state.phase),
      StudioPhase.draftReady ||
      StudioPhase.awaitingApproval =>
        _DraftView(
          state: state,
          onApprove: _onApprove,
          // B2: Caption regeneration callback'i
          onRegenerate: _onRegenerate,
        ),
      StudioPhase.rendering => _RenderingView(),
      StudioPhase.completed => _CompletedView(state: state),
      StudioPhase.failed => _FailedView(
          message: state.errorMessage ?? context.l10n.unknownError,
          onRetry: _startPreview,
        ),
    };
  }

  void _onApprove() {
    final directorState = ref.read(directorProvider);
    final profile = ref.read(userProfileProvider);
    if (directorState.session == null || profile == null) return;

    // B1: Kredit yeterliliği kontrolü
    if (!ref.read(userProfileProvider.notifier).hasEnoughCredits) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.insufficientCreditsSnackbar),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => _CreditConfirmDialog(
        credits: ref.read(studioProvider).creditsRequired,
        remainingCredits: profile.credits,
        onConfirm: () {
          Navigator.pop(context);
          ref.read(studioProvider.notifier).approveAndRender(
                session: directorState.session!,
                userProfile: profile,
              );
        },
      ),
    );
  }

  /// B2: "Yeniden Yaz" butonundan gelen callback.
  void _onRegenerate() {
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;
    ref.read(studioProvider.notifier).regenerateCaption(userProfile: profile);
  }
}

class _LoadingView extends StatelessWidget {
  final StudioPhase phase;
  const _LoadingView({required this.phase});

  String _getMessage(BuildContext context) => switch (phase) {
        StudioPhase.buildingPrompt => context.l10n.loadingBuildingPrompt,
        StudioPhase.generatingCaption => context.l10n.loadingGeneratingCaption,
        _ => context.l10n.loadingGeneric,
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFFC9A96E)),
          const SizedBox(height: 20),
          Text(
            _getMessage(context),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DraftView extends StatelessWidget {
  final StudioState state;
  final VoidCallback onApprove;
  // B2: Caption regeneration callback
  final VoidCallback onRegenerate;

  const _DraftView({
    required this.state,
    required this.onApprove,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video önizleme alanı
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_circle_outline,
                      size: 56, color: Color(0xFFC9A96E)),
                  const SizedBox(height: 8),
                  Text(
                    l10n.draftPreviewLabel,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Oluşturulan açıklama
          if (state.generatedCaption != null) ...[
            Text(l10n.aiCaptionSectionTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Text(
                state.generatedCaption!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // B2: onRegenerate callback ile Gemini'ye yeniden istek at
            TextButton.icon(
              onPressed: state.phase == StudioPhase.generatingCaption
                  ? null // yükleme sırasında devre dışı
                  : onRegenerate,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(l10n.regenerateCaptionButton),
            ),
          ],
          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: state.phase == StudioPhase.awaitingApproval
                ? onApprove
                : null,
            icon: const Icon(Icons.auto_awesome),
            label: Text(l10n.upscaleButton),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.toll, color: Color(0xFFC9A96E), size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.creditsWillBeUsed(state.creditsRequired),
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RenderingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFFC9A96E)),
          const SizedBox(height: 20),
          Text(
            context.l10n.renderingTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.renderingSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CompletedView extends StatelessWidget {
  final StudioState state;
  const _CompletedView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF38A169), size: 72),
            const SizedBox(height: 20),
            Text(
              '${context.l10n.contentReadyTitle} 🎉',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 32),
            // B3: TODO Phase 2 — share_plus ile caption + video paylaş
            ElevatedButton.icon(
              onPressed: () {
                // TODO Phase 2: share_plus ile Instagram paylaşımı
                // Share.shareXFiles([XFile(localPath)], text: caption);
              },
              icon: const Icon(Icons.share),
              label: Text(context.l10n.shareInstagramButton),
            ),
            const SizedBox(height: 12),
            // B3: TODO Phase 2 — image_picker / gallery_saver ile kaydet
            OutlinedButton(
              onPressed: () {
                // TODO Phase 2: GallerySaver.saveVideo(videoUrl)
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: Color(0xFF2A2A2A)),
              ),
              child: Text(context.l10n.saveToGalleryButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailedView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FailedView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE53E3E), size: 64),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(context.l10n.studioRetryButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditConfirmDialog extends StatelessWidget {
  final int credits;
  final int remainingCredits;
  final VoidCallback onConfirm;

  const _CreditConfirmDialog({
    required this.credits,
    required this.remainingCredits,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.creditDialogTitle),
      content: Text(
        l10n.creditDialogBody(
          credits,
          remainingCredits,
          remainingCredits - credits,
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.creditDialogCancel, style: const TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: Text(l10n.creditDialogConfirm),
        ),
      ],
    );
  }
}
