import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_router.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../domain/entities/user_profile.dart';
import '../providers/onboarding_provider.dart';

class VoiceRecordingScreen extends ConsumerStatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  ConsumerState<VoiceRecordingScreen> createState() =>
      _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends ConsumerState<VoiceRecordingScreen>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _hasRecording = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// UserProfile'ı Onboarding state'inden oluşturur ve Firestore'a kaydeder.
  /// Firebase Auth UID + email kullanır.
  Future<void> _initUserProfile() async {
    final ob = ref.read(onboardingProvider);
    if (ob.availableSectors.isEmpty) return;

    final sector = ob.availableSectors.firstWhere(
      (s) => s.id == ob.selectedSectorId,
      orElse: () => ob.availableSectors.first,
    );

    final currentUser = ref.read(authServiceProvider).currentUser;
    final uid = currentUser?.uid ?? 'user_001';
    final email = currentUser?.email ?? '';

    await ref.read(userProfileProvider.notifier).initialize(
          uid: uid,
          email: email,
          businessName: ob.businessName ?? 'İşletmem',
          sector: sector,
          topProducts: ob.topProducts,
          vibe: ob.vibe ?? BusinessVibe.friendly,
          audience: ob.audience ?? TargetAudience.mixed,
          brandToneAnalysis: ob.brandToneAnalysis,
        );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
        _hasRecording = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marka Sesini Kaydet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFFC9A96E),
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '15 saniyede dükkanını anlat',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI, konuşma tonundan markanın karakterini ve enerjisini analiz edecek. '
                    'Doğal konuş, performans yapma.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _pulseAnimation.value : 1.0,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? const Color(0xFFE53E3E)
                        : const Color(0xFFC9A96E),
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 40,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isRecording
                  ? 'Kayıt yapılıyor...'
                  : _hasRecording
                      ? 'Kayıt tamamlandı ✓'
                      : 'Mikrofona bas ve konuş',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _isRecording
                    ? const Color(0xFFE53E3E)
                    : _hasRecording
                        ? const Color(0xFF38A169)
                        : Colors.white54,
              ),
            ),
            const Spacer(),
            if (state.isAnalyzingVoice)
              Column(
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFFC9A96E),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI markanı analiz ediyor...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              )
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _hasRecording
                        ? () async {
                            await ref
                                .read(onboardingProvider.notifier)
                                .analyzeVoiceRecording('simulated_audio.m4a');
                            if (context.mounted) {
                              await _initUserProfile();
                              if (context.mounted) {
                                context.go(AppRoutes.director);
                              }
                            }
                          }
                        : null,
                    child: const Text('Analiz Et ve Başla'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      await _initUserProfile();
                      if (context.mounted) context.go(AppRoutes.director);
                    },
                    child: Text(
                      'Şimdilik atla',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
