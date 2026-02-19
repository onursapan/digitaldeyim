import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final renderRepositoryProvider =
    Provider<RenderRepository>((ref) => RenderRepository());

enum RenderStatus { pending, processing, done, failed }

class RenderRecord {
  final String id;
  final String sessionId;
  final String userId;
  final RenderStatus status;
  final String? shotstackRenderId;
  final String? outputUrl;
  final DateTime createdAt;

  const RenderRecord({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.status,
    this.shotstackRenderId,
    this.outputUrl,
    required this.createdAt,
  });
}

class RenderRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Logger _log = Logger();

  CollectionReference get _renders => _db.collection('renders');

  Future<String> create({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final doc = await _renders.add({
        'sessionId': sessionId,
        'userId': userId,
        'status': RenderStatus.pending.name,
        'shotstackRenderId': null,
        'outputUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _log.i('Render record created: ${doc.id}');
      return doc.id;
    } catch (e) {
      _log.e('Failed to create render record: $e');
      rethrow;
    }
  }

  Future<void> updateShotstackId(
      String renderId, String shotstackRenderId) async {
    try {
      await _renders.doc(renderId).update({
        'shotstackRenderId': shotstackRenderId,
        'status': RenderStatus.processing.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _log.e('Failed to update shotstack render id: $e');
      rethrow;
    }
  }

  Future<void> complete(String renderId, String outputUrl) async {
    try {
      await _renders.doc(renderId).update({
        'outputUrl': outputUrl,
        'status': RenderStatus.done.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _log.i('Render completed: $renderId → $outputUrl');
    } catch (e) {
      _log.e('Failed to complete render: $e');
      rethrow;
    }
  }

  Future<void> fail(String renderId, String reason) async {
    try {
      await _renders.doc(renderId).update({
        'status': RenderStatus.failed.name,
        'failReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _log.e('Failed to mark render as failed: $e');
      rethrow;
    }
  }

  Stream<RenderRecord?> watch(String renderId) {
    return _renders.doc(renderId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      final map = snap.data() as Map<String, dynamic>;
      return RenderRecord(
        id: snap.id,
        sessionId: map['sessionId'] as String,
        userId: map['userId'] as String,
        status: RenderStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => RenderStatus.pending,
        ),
        shotstackRenderId: map['shotstackRenderId'] as String?,
        outputUrl: map['outputUrl'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    });
  }
}
