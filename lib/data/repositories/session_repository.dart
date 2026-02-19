import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/sector.dart';
import '../../domain/entities/shoot_session.dart';

final sessionRepositoryProvider =
    Provider<SessionRepository>((ref) => SessionRepository());

class SessionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Logger _log = Logger();

  CollectionReference get _sessions => _db.collection('sessions');

  Future<void> save(ShootSession session) async {
    try {
      await _sessions
          .doc(session.id)
          .set(_toMap(session), SetOptions(merge: true));
      _log.i('Session saved: ${session.id}');
    } catch (e) {
      _log.e('Failed to save session: $e');
      rethrow;
    }
  }

  Future<ShootSession?> get(String sessionId) async {
    try {
      final doc = await _sessions.doc(sessionId).get();
      if (!doc.exists || doc.data() == null) return null;
      return _fromMap(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      _log.e('Failed to get session: $e');
      rethrow;
    }
  }

  Future<void> updateStatus(String sessionId, SessionStatus status) async {
    try {
      await _sessions.doc(sessionId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _log.e('Failed to update session status: $e');
      rethrow;
    }
  }

  Future<void> updateFinalUrl(String sessionId, String videoUrl) async {
    try {
      await _sessions.doc(sessionId).update({
        'finalVideoUrl': videoUrl,
        'status': SessionStatus.completed.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _log.e('Failed to update final video url: $e');
      rethrow;
    }
  }

  Stream<List<ShootSession>> watchUserSessions(String userId) {
    return _sessions
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                _fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Map<String, dynamic> _toMap(ShootSession s) => {
        'userId': s.userId,
        'sectorId': s.sector.id,
        'sectorName': s.sector.name,
        'sectorEmoji': s.sector.emoji,
        'clips': s.clips.map(_clipToMap).toList(),
        'status': s.status.name,
        'draftVideoPath': s.draftVideoPath,
        'finalVideoUrl': s.finalVideoUrl,
        'createdAt': s.createdAt.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  ShootSession _fromMap(String id, Map<String, dynamic> map) {
    // Minimal stub sector — tam sector verisi onboarding asset'inden gelir
    final sector = _buildStubSector(
      id: map['sectorId'] as String? ?? 'unknown',
      name: map['sectorName'] as String? ?? '',
      emoji: map['sectorEmoji'] as String? ?? '🏪',
    );

    return ShootSession(
      id: id,
      userId: map['userId'] as String,
      sector: sector,
      clips: (map['clips'] as List<dynamic>? ?? [])
          .map((c) => _clipFromMap(c as Map<String, dynamic>))
          .toList(),
      status: SessionStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SessionStatus.shooting,
      ),
      draftVideoPath: map['draftVideoPath'] as String?,
      finalVideoUrl: map['finalVideoUrl'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> _clipToMap(ShootClip c) => {
        'stepId': c.stepId,
        'localPath': c.localPath,
        'status': c.status.name,
      };

  ShootClip _clipFromMap(Map<String, dynamic> map) => ShootClip(
        stepId: map['stepId'] as String,
        localPath: map['localPath'] as String? ?? '',
        status: ClipStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => ClipStatus.recorded,
        ),
      );

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
