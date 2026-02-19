import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/onboarding/screens/sector_selection_screen.dart';
import '../presentation/onboarding/screens/business_info_screen.dart';
import '../presentation/onboarding/screens/voice_recording_screen.dart';
import '../presentation/director/screens/director_screen.dart';
import '../presentation/studio/screens/studio_screen.dart';
import '../presentation/onboarding/providers/onboarding_provider.dart';

class AppRoutes {
  static const sectorSelection = '/';
  static const businessInfo = '/business-info';
  static const voiceRecording = '/voice-recording';
  static const director = '/director';
  static const studio = '/studio';
}

/// B5: GoRouter'ı onboarding state değişimlerine karşı reaktif kılan notifier.
/// Riverpod ref'ini dinleyerek route redirect kararlarını verir.
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    // Onboarding state değiştiğinde GoRouter'ı yenile → redirect yeniden tetiklenir.
    _ref.listen(onboardingProvider, (context, state) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final onboarding = _ref.read(onboardingProvider);
    const protected = {AppRoutes.director, AppRoutes.studio};

    if (protected.contains(state.matchedLocation) &&
        !onboarding.canProceedToDirector) {
      // Onboarding tamamlanmadan /director veya /studio'ya erişim engellenir.
      return AppRoutes.sectorSelection;
    }

    return null;
  }
}

/// B5: GoRouter bir Riverpod Provider'a taşındı.
/// main.dart'ta `ref.watch(appRouterProvider)` ile kullanılır.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.sectorSelection,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.sectorSelection,
        builder: (context, state) => const SectorSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.businessInfo,
        builder: (context, state) => const BusinessInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.voiceRecording,
        builder: (context, state) => const VoiceRecordingScreen(),
      ),
      GoRoute(
        path: AppRoutes.director,
        builder: (context, state) => const DirectorScreen(),
      ),
      GoRoute(
        path: AppRoutes.studio,
        builder: (context, state) => const StudioScreen(),
      ),
    ],
  );
});
