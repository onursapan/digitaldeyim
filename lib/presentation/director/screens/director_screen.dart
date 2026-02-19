import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_router.dart';
import '../../../core/agents/validator_agent.dart';
import '../../../domain/entities/sector.dart';
import '../../../domain/entities/shoot_session.dart';
import '../providers/director_provider.dart';
import '../../../presentation/onboarding/providers/onboarding_provider.dart';

class DirectorScreen extends ConsumerStatefulWidget {
  const DirectorScreen({super.key});

  @override
  ConsumerState<DirectorScreen> createState() => _DirectorScreenState();
}

class _DirectorScreenState extends ConsumerState<DirectorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSession());
  }

  void _initSession() {
    final onboardingState = ref.read(onboardingProvider);
    final sectorId = onboardingState.selectedSectorId;
    if (sectorId == null) return;

    final sector = onboardingState.availableSectors
        .firstWhere((s) => s.id == sectorId);

    ref.read(directorProvider.notifier).initSession(
          sector: sector,
          userId: 'user_001', // Faz 2'de Firebase Auth UID kullanılacak
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(directorProvider);

    if (state.session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final session = state.session!;
    final step = state.currentStep;
    final steps = session.sector.directorBrief.steps;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simüle kamera preview — Gerçekte CameraPreview widget
          _SimulatedCameraView(isRecording: state.isRecording),

          // Ghost Overlay — çekim rehberi
          if (step != null)
            _GhostOverlay(step: step, sector: session.sector),

          // Live validation feedback
          if (state.liveFeedback != null)
            _LiveValidationBar(feedback: state.liveFeedback!),

          // Bottom Director Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _DirectorPanel(
              state: state,
              steps: steps,
              onRecord: () => _handleRecord(state),
              onNext: () => ref.read(directorProvider.notifier).nextStep(),
              onGoToStudio: () => context.go(AppRoutes.studio),
            ),
          ),

          // Validation error banner
          if (state.errorMessage != null)
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: _ErrorBanner(
                message: state.errorMessage!,
                onRetake: () =>
                    ref.read(directorProvider.notifier).retakeCurrentClip(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleRecord(DirectorState state) async {
    final notifier = ref.read(directorProvider.notifier);
    if (state.isRecording) {
      // Çekimi durdur ve validate et
      // Faz 2: Gerçek CameraController.stopVideoRecording() buraya gelir
      const simulatedPath = 'local://simulated_clip.mp4';
      await notifier.stopRecordingAndValidate(simulatedPath);
    } else {
      notifier.startRecording();
      // Faz 2: CameraController.startVideoRecording() buraya gelir
    }
  }
}

class _SimulatedCameraView extends StatelessWidget {
  final bool isRecording;
  const _SimulatedCameraView({required this.isRecording});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF0D0D0D),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt,
              size: 64,
              color: isRecording
                  ? const Color(0xFFE53E3E)
                  : Colors.white24,
            ),
            const SizedBox(height: 8),
            Text(
              isRecording ? '● REC' : 'Kamera Hazır',
              style: TextStyle(
                color: isRecording
                    ? const Color(0xFFE53E3E)
                    : Colors.white24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GhostOverlay extends StatelessWidget {
  final ShootStep step;
  final Sector sector;

  const _GhostOverlay({required this.step, required this.sector});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Adım başlığı
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              step.title,
              style: const TextStyle(
                color: Color(0xFFC9A96E),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Overlay ipucu
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color(0xFFC9A96E).withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              step.overlayHint,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveValidationBar extends StatelessWidget {
  final LiveValidationFeedback feedback;
  const _LiveValidationBar({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 130,
      right: 16,
      child: Column(
        children: [
          _ValidationDot(
            icon: Icons.light_mode,
            ok: feedback.lightingOk,
            label: 'Işık',
          ),
          const SizedBox(height: 8),
          _ValidationDot(
            icon: Icons.motion_photos_on,
            ok: feedback.stabilityOk,
            label: 'Sabit',
          ),
        ],
      ),
    );
  }
}

class _ValidationDot extends StatelessWidget {
  final IconData icon;
  final bool ok;
  final String label;

  const _ValidationDot({required this.icon, required this.ok, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: ok ? const Color(0xFF38A169) : const Color(0xFFE53E3E), size: 20),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: ok ? const Color(0xFF38A169) : const Color(0xFFE53E3E),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectorPanel extends StatelessWidget {
  final DirectorState state;
  final List<ShootStep> steps;
  final VoidCallback onRecord;
  final VoidCallback onNext;
  final VoidCallback onGoToStudio;

  const _DirectorPanel({
    required this.state,
    required this.steps,
    required this.onRecord,
    required this.onNext,
    required this.onGoToStudio,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = state.session?.clips
            .where((c) => c.status == ClipStatus.validated)
            .length ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black, Colors.black.withValues(alpha: 0)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Adım indikatörü
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: steps.asMap().entries.map((e) {
              final isDone = e.key < completedCount;
              final isCurrent = e.key == state.currentStepIndex;
              return Container(
                width: isCurrent ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isDone
                      ? const Color(0xFF38A169)
                      : isCurrent
                          ? const Color(0xFFC9A96E)
                          : Colors.white24,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Mevcut adım talimatı
          if (state.currentStep != null)
            Text(
              state.currentStep!.instruction,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
          const SizedBox(height: 20),

          // Kayıt / Sonraki / Stüdyoya git
          if (state.allClipsValidated)
            ElevatedButton.icon(
              onPressed: onGoToStudio,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Stüdyoya Git'),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Kayıt butonu
                GestureDetector(
                  onTap: state.isValidating ? null : onRecord,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isRecording
                          ? const Color(0xFFE53E3E)
                          : Colors.white,
                      border: Border.all(
                        color: state.isRecording
                            ? Color(0xFFE53E3E).withValues(alpha: 0.4)
                            : Colors.transparent,
                        width: 4,
                      ),
                    ),
                    child: state.isValidating
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : Icon(
                            state.isRecording ? Icons.stop : Icons.fiber_manual_record,
                            size: 32,
                            color: Colors.black,
                          ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetake;

  const _ErrorBanner({required this.message, required this.onRetake});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFFE53E3E).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetake,
            child: const Text(
              'Tekrar çek',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
