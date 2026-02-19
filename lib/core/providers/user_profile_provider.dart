import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../domain/entities/sector.dart';
import '../../domain/entities/user_profile.dart';

/// Uygulama genelinde paylaşılan mutable UserProfile.
/// - Onboarding tamamlandığında initialize() çağrılır.
/// - Render onaylandığında deductCredits() çağrılır.
/// - Faz 2: Firebase Auth UID + Firestore ile replace edilir.
class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(null);

  void initialize({
    required String businessName,
    required Sector sector,
    required List<String> topProducts,
    required BusinessVibe vibe,
    required TargetAudience audience,
    String? brandToneAnalysis,
  }) {
    state = UserProfile(
      id: 'user_001', // Faz 2: Firebase Auth UID
      email: '',
      businessName: businessName,
      sector: sector,
      topProducts: topProducts,
      vibe: vibe,
      audience: audience,
      brandToneAnalysis: brandToneAnalysis,
      credits: AppConfig.initialCredits,
      createdAt: DateTime.now(),
    );
  }

  /// Render tamamlandığında kredit düş. Sıfırın altına inmez.
  void deductCredits(int amount) {
    if (state == null) return;
    final newCredits = (state!.credits - amount).clamp(0, 999);
    state = state!.copyWith(credits: newCredits);
  }

  bool get hasEnoughCredits =>
      (state?.credits ?? 0) >= AppConfig.renderCostPerVideo;
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>(
  (ref) => UserProfileNotifier(),
);
