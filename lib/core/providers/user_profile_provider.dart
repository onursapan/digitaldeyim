import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../domain/entities/sector.dart';
import '../../domain/entities/user_profile.dart';

/// Uygulama genelinde paylaşılan mutable UserProfile.
/// - Onboarding tamamlandığında initialize() çağrılır ve Firestore'a kaydedilir.
/// - Render onaylandığında deductCredits() çağrılır — hem local hem Firestore güncellenir.
/// - loadFromFirestore() ile mevcut kullanıcı oturumu restore edilir.
class UserProfileNotifier extends StateNotifier<UserProfile?> {
  final Ref _ref;

  UserProfileNotifier(this._ref) : super(null);

  UserProfileRepository get _repo =>
      _ref.read(userProfileRepositoryProvider);

  /// Onboarding tamamlandığında çağrılır.
  /// Firebase Auth UID'si ile profile oluşturur, Firestore'a kaydeder.
  Future<void> initialize({
    required String uid,
    required String email,
    required String businessName,
    required Sector sector,
    required List<String> topProducts,
    required BusinessVibe vibe,
    required TargetAudience audience,
    String? brandToneAnalysis,
  }) async {
    final profile = UserProfile(
      id: uid,
      email: email,
      businessName: businessName,
      sector: sector,
      topProducts: topProducts,
      vibe: vibe,
      audience: audience,
      brandToneAnalysis: brandToneAnalysis,
      credits: AppConfig.initialCredits,
      createdAt: DateTime.now(),
    );
    state = profile;
    await _repo.save(profile);
  }

  /// Login sonrası Firestore'dan mevcut profili yükler.
  Future<void> loadFromFirestore(String uid) async {
    final profile = await _repo.get(uid);
    if (profile != null) state = profile;
  }

  /// Render tamamlandığında kredit düş — local + Firestore senkronize.
  Future<void> deductCredits(int amount) async {
    if (state == null) return;
    final newCredits = (state!.credits - amount).clamp(0, 999);
    state = state!.copyWith(credits: newCredits);
    await _repo.deductCredits(state!.id, amount);
  }

  bool get hasEnoughCredits =>
      (state?.credits ?? 0) >= AppConfig.renderCostPerVideo;

  void clear() => state = null;
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>(
  (ref) => UserProfileNotifier(ref),
);
