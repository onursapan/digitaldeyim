import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

/// Firebase Storage upload paths:
/// voices/{uid}/{filename}.m4a
/// clips/{uid}/{sessionId}/{stepId}.mp4
/// photos/{uid}/{sessionId}/{filename}.jpg
/// renders/{uid}/{sessionId}/final.mp4
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _log = Logger();

  /// Ses kaydını Storage'a yükler. Marka tonu analizi için kullanılır.
  Future<String> uploadVoiceRecording({
    required String uid,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final filename = '${DateTime.now().millisecondsSinceEpoch}.m4a';
    final ref = _storage.ref('voices/$uid/$filename');
    return _upload(ref: ref, file: file, onProgress: onProgress);
  }

  /// Director modunda çekilen ham klip videosunu yükler.
  Future<String> uploadClip({
    required String uid,
    required String sessionId,
    required String stepId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final ext = p.extension(file.path).isNotEmpty
        ? p.extension(file.path)
        : '.mp4';
    final ref = _storage.ref('clips/$uid/$sessionId/$stepId$ext');
    return _upload(ref: ref, file: file, onProgress: onProgress);
  }

  /// Ürün veya mağaza fotoğrafını yükler.
  Future<String> uploadPhoto({
    required String uid,
    required String sessionId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final filename =
        '${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
    final ref = _storage.ref('photos/$uid/$sessionId/$filename');
    return _upload(ref: ref, file: file, onProgress: onProgress);
  }

  /// Shotstack render çıktısını Storage'a kopyalar (URL'den indirip yükler).
  /// Final 4K video kalıcı olarak saklanır.
  Future<String> uploadRenderOutput({
    required String uid,
    required String sessionId,
    required File file,
  }) async {
    final ref = _storage.ref('renders/$uid/$sessionId/final.mp4');
    return _upload(ref: ref, file: file);
  }

  /// Verilen Storage path'indeki dosyayı siler.
  Future<void> delete(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
      _log.i('Deleted: $storagePath');
    } catch (e) {
      _log.w('Delete failed (may not exist): $storagePath — $e');
    }
  }

  /// Download URL döner; upload tamamlanana kadar bekler.
  Future<String> _upload({
    required Reference ref,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final task = ref.putFile(file);

      if (onProgress != null) {
        task.snapshotEvents.listen((snap) {
          if (snap.totalBytes > 0) {
            onProgress(snap.bytesTransferred / snap.totalBytes);
          }
        });
      }

      final snapshot = await task;
      final url = await snapshot.ref.getDownloadURL();
      _log.i('Uploaded to ${ref.fullPath} → $url');
      return url;
    } on FirebaseException catch (e) {
      _log.e('FirebaseException uploading to ${ref.fullPath}: ${e.code}');
      rethrow;
    } catch (e) {
      _log.e('Unexpected error uploading to ${ref.fullPath}: $e');
      rethrow;
    }
  }
}
