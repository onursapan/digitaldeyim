import 'package:go_router/go_router.dart';
import '../presentation/onboarding/screens/sector_selection_screen.dart';
import '../presentation/onboarding/screens/business_info_screen.dart';
import '../presentation/onboarding/screens/voice_recording_screen.dart';
import '../presentation/director/screens/director_screen.dart';
import '../presentation/studio/screens/studio_screen.dart';

class AppRoutes {
  static const sectorSelection = '/';
  static const businessInfo = '/business-info';
  static const voiceRecording = '/voice-recording';
  static const director = '/director';
  static const studio = '/studio';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.sectorSelection,
  routes: [
    GoRoute(
      path: AppRoutes.sectorSelection,
      builder: (_, _) => const SectorSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.businessInfo,
      builder: (_, _) => const BusinessInfoScreen(),
    ),
    GoRoute(
      path: AppRoutes.voiceRecording,
      builder: (_, _) => const VoiceRecordingScreen(),
    ),
    GoRoute(
      path: AppRoutes.director,
      builder: (_, _) => const DirectorScreen(),
    ),
    GoRoute(
      path: AppRoutes.studio,
      builder: (_, _) => const StudioScreen(),
    ),
  ],
);
