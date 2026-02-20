import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // serverClientId → Android'de idToken üretimi için Web OAuth client (type 3) zorunlu.
  // iOS'ta CLIENT_ID, GoogleService-Info.plist'ten otomatik okunur.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '349706854240-09tov0eid9lgmq7i8lbd34v6o8bdqjgm.apps.googleusercontent.com',
  );
  final Logger _log = Logger();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => _auth.currentUser != null;

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      _log.i('Google sign-in successful: ${userCredential.user?.email}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      _log.e('FirebaseAuthException during Google sign-in: ${e.code}');
      rethrow;
    } catch (e) {
      _log.e('Unexpected error during Google sign-in: $e');
      rethrow;
    }
  }

  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      _log.i('Anonymous sign-in successful: ${userCredential.user?.uid}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      _log.e('FirebaseAuthException during anonymous sign-in: ${e.code}');
      rethrow;
    } catch (e) {
      _log.e('Unexpected error during anonymous sign-in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      _log.i('User signed out');
    } catch (e) {
      _log.e('Error signing out: $e');
      rethrow;
    }
  }
}
