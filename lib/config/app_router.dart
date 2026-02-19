import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/auth/screens/login_screen.dart';
import '../presentation/onboarding/screens/sector_selection_screen.dart';
import '../presentation/onboarding/screens/business_info_screen.dart';
import '../presentation/onboarding/screens/voice_recording_screen.dart';
import '../presentation/director/screens/director_screen.dart';
import '../presentation/studio/screens/studio_screen.dart';
import '../presentation/onboarding/providers/onboarding_provider.dart';
import '../core/services/auth_service.dart';

class AppRoutes {
  static const login = '/login';
  static const sectorSelection = '/';
  static const businessInfo = '/business-info';
  static const voiceRecording = '/voice-recording';
  static const director = '/director';
  static const studio = '/studio';
}

/// GoRouter'ı auth + onboarding state değişimlerine karşı reaktif kılan notifier.
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (prev, next) => notifyListeners());
    _ref.listen(onboardingProvider, (prev, next) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(authStateProvider);
    final onboarding = _ref.read(onboardingProvider);

    final isLoggedIn = authAsync.valueOrNull != null;
    final isOnLogin = state.matchedLocation == AppRoutes.login;
    const onboardingRoutes = {
      AppRoutes.sectorSelection,
      AppRoutes.businessInfo,
      AppRoutes.voiceRecording,
    };
    const protectedRoutes = {AppRoutes.director, AppRoutes.studio};

    // Not logged in → force to login (except already on login)
    if (!isLoggedIn && !isOnLogin) return AppRoutes.login;

    // Logged in but on login page → go to onboarding start
    if (isLoggedIn && isOnLogin) return AppRoutes.sectorSelection;

    // Logged in, onboarding not complete → block director/studio
    if (isLoggedIn &&
        protectedRoutes.contains(state.matchedLocation) &&
        !onboarding.canProceedToDirector) {
      return AppRoutes.sectorSelection;
    }

    // Logged in, onboarding complete → skip onboarding screens if trying to revisit
    if (isLoggedIn &&
        onboarding.canProceedToDirector &&
        onboardingRoutes.contains(state.matchedLocation)) {
      return null; // allow — user may want to change settings
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
    initialLocation: AppRoutes.login,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
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
