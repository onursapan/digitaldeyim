import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/sector.dart';
import '../../domain/entities/user_profile.dart';

final userProfileRepositoryProvider =
    Provider<UserProfileRepository>((ref) => UserProfileRepository());

class UserProfileRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Logger _log = Logger();

  CollectionReference get _users => _db.collection('users');

  Future<void> save(UserProfile profile) async {
    try {
      await _users.doc(profile.id).set(_toMap(profile), SetOptions(merge: true));
      _log.i('UserProfile saved: ${profile.id}');
    } catch (e) {
      _log.e('Failed to save UserProfile: $e');
      rethrow;
    }
  }

  Future<UserProfile?> get(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return _fromMap(uid, doc.data() as Map<String, dynamic>);
    } catch (e) {
      _log.e('Failed to get UserProfile: $e');
      rethrow;
    }
  }

  Future<void> deductCredits(String uid, int amount) async {
    try {
      await _users.doc(uid).update({
        'credits': FieldValue.increment(-amount),
      });
    } catch (e) {
      _log.e('Failed to deduct credits: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _toMap(UserProfile p) => {
        'email': p.email,
        'businessName': p.businessName,
        'sectorId': p.sector.id,
        'sectorName': p.sector.name,
        'sectorEmoji': p.sector.emoji,
        'topProducts': p.topProducts,
        'vibe': p.vibe.name,
        'audience': p.audience.name,
        'brandToneAnalysis': p.brandToneAnalysis,
        'credits': p.credits,
        'createdAt': p.createdAt.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Firestore'dan okunan profil minimal Sector ile döner.
  /// Tam Sector verisi (directorBrief, visualStyle) onboarding asset'inden yüklenir.
  /// Bu metod sadece auth restore için kullanılır — onboarding akışında
  /// gerçek Sector nesnesi asset'ten gelir.
  UserProfile _fromMap(String uid, Map<String, dynamic> map) {
    final stubSector = _buildStubSector(
      id: map['sectorId'] as String? ?? 'unknown',
      name: map['sectorName'] as String? ?? '',
      emoji: map['sectorEmoji'] as String? ?? '🏪',
    );

    return UserProfile(
      id: uid,
      email: map['email'] as String? ?? '',
      businessName: map['businessName'] as String? ?? '',
      sector: stubSector,
      topProducts: List<String>.from(map['topProducts'] ?? []),
      vibe: BusinessVibe.values.firstWhere(
        (v) => v.name == map['vibe'],
        orElse: () => BusinessVibe.friendly,
      ),
      audience: TargetAudience.values.firstWhere(
        (a) => a.name == map['audience'],
        orElse: () => TargetAudience.mixed,
      ),
      brandToneAnalysis: map['brandToneAnalysis'] as String?,
      credits: (map['credits'] as num?)?.toInt() ?? 3,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Minimal Sector — sadece id/name/emoji içerir.
  /// Tam director brief ve visual style onboarding asset'inden yüklenecek.
  Sector _buildStubSector({
    required String id,
    required String name,
    required String emoji,
  }) {
    const defaultChecklist = CameraChecklist(
      minLux: 300,
      maxShake: 0.5,
      lightingTip: 'Işığın önden gelmesine dikkat et.',
      backgroundTip: 'Sade bir arka plan seç.',
    );
    const defaultStep = ShootStep(
      id: 'stub',
      title: '',
      instruction: '',
      overlayHint: '',
      durationSeconds: 5,
      motion: CameraMotion.still,
    );
    const defaultBrief = SectorDirectorBrief(
      hook: defaultStep,
      detail: defaultStep,
      exit: defaultStep,
      checklist: defaultChecklist,
    );
    const defaultVisual = SectorVisualStyle(
      primaryColorHex: '#6C63FF',
      accentColorHex: '#C9A96E',
      fontStyle: 'modern',
      musicMood: 'upbeat',
      cutRhythm: 2.5,
      shotstackTemplateIds: [],
    );

    return Sector(
      id: id,
      name: name,
      emoji: emoji,
      directorBrief: defaultBrief,
      visualStyle: defaultVisual,
    );
  }
}
