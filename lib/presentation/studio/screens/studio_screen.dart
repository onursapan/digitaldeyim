import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/user_profile.dart';
import '../providers/studio_provider.dart';
import '../../director/providers/director_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';

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
    if (directorState.session == null) return;

    // Faz 2'de gerçek UserProfile Firebase'den gelecek
    ref.read(studioProvider.notifier).preparePreview(
          session: directorState.session!,
          userProfile: _buildProfile(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studioProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taslak Stüdyo'),
        actions: [
          if (state.phase == StudioPhase.awaitingApproval)
            TextButton(
              onPressed: () => ref.read(studioProvider.notifier).rejectDraft(),
              child: const Text(
                'Reddet',
                style: TextStyle(color: Color(0xFFE53E3E)),
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
        _DraftView(state: state, onApprove: _onApprove),
      StudioPhase.rendering => _RenderingView(),
      StudioPhase.completed => _CompletedView(state: state),
      StudioPhase.failed => _FailedView(
          message: state.errorMessage ?? 'Bilinmeyen hata.',
          onRetry: _startPreview,
        ),
    };
  }

  void _onApprove() {
    final directorState = ref.read(directorProvider);
    if (directorState.session == null) return;

    showDialog(
      context: context,
      builder: (_) => _CreditConfirmDialog(
        credits: ref.read(studioProvider).creditsRequired,
        onConfirm: () {
          Navigator.pop(context);
          ref.read(studioProvider.notifier).approveAndRender(
                session: directorState.session!,
                userProfile: _buildProfile(),
              );
        },
      ),
    );
  }

  // Faz 2'de Firebase'den gelecek — şimdilik onboarding state'inden inşa ediyoruz
  UserProfile _buildProfile() {
    final ob = ref.read(onboardingProvider);
    return UserProfile(
      id: 'user_001',
      email: '',
      businessName: ob.businessName ?? 'İşletmem',
      sector: ob.availableSectors.firstWhere(
        (s) => s.id == ob.selectedSectorId,
        orElse: () => ob.availableSectors.first,
      ),
      topProducts: ob.topProducts,
      vibe: ob.vibe ?? BusinessVibe.friendly,
      audience: ob.audience ?? TargetAudience.mixed,
      brandToneAnalysis: ob.brandToneAnalysis,
      createdAt: DateTime.now(),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final StudioPhase phase;
  const _LoadingView({required this.phase});

  String get _message => switch (phase) {
        StudioPhase.buildingPrompt => 'İçerik kurgusu hazırlanıyor...',
        StudioPhase.generatingCaption => 'AI açıklama yazıyor...',
        _ => 'Yükleniyor...',
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
            _message,
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

  const _DraftView({required this.state, required this.onApprove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_outline,
                      size: 56, color: Color(0xFFC9A96E)),
                  SizedBox(height: 8),
                  Text(
                    'Taslak Önizleme',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Oluşturulan açıklama
          if (state.generatedCaption != null) ...[
            Text('AI Açıklama', style: theme.textTheme.titleLarge),
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
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Yeniden Yaz'),
            ),
          ],
          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: state.phase == StudioPhase.awaitingApproval
                ? onApprove
                : null,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('4K\'ya Yükselt'),
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
                  '${state.creditsRequired} kredi kullanılacak',
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
            '4K render yapılıyor...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'İçerik hazır olunca bildirim alacaksın.',
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
              'İçerik Hazır! 🎉',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share),
              label: const Text('Instagram\'a Paylaş'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: Color(0xFF2A2A2A)),
              ),
              child: const Text('Galeriye Kaydet'),
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
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditConfirmDialog extends StatelessWidget {
  final int credits;
  final VoidCallback onConfirm;

  const _CreditConfirmDialog({required this.credits, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Render Onayı'),
      content: Text(
        'Bu içeriği 4K ve AI efektleriyle oluşturmak için $credits kredin kullanılacak. Devam etmek istiyor musun?',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('Onayla'),
        ),
      ],
    );
  }
}
