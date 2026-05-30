import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rensius/data/auth_data.dart';
import 'package:rensius/services/firebase_service.dart';

class FirebaseAuthService {
  FirebaseAuthService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static User? get currentUser {
    if (!FirebaseService.isInitialized) return null;
    return _auth.currentUser;
  }

  static Stream<User?> authStateChanges() {
    if (!FirebaseService.isInitialized) {
      return const Stream<User?>.empty();
    }
    return _auth.authStateChanges();
  }

  static Future<UserCredential> registerEndUser({
    required UserAccount account,
  }) async {
    _assertInitialized();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: account.email,
      password: account.password,
    );

    await credential.user?.updateDisplayName(account.applicantName);
    await saveUserProfile(account, uid: credential.user!.uid);

    return credential;
  }

  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _assertInitialized();

    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    _assertInitialized();
    await _auth.sendPasswordResetEmail(email: email);
  }

  static Future<void> signOut() async {
    if (!FirebaseService.isInitialized) return;
    await _auth.signOut();
  }

  static Future<void> saveUserProfile(
    UserAccount account, {
    String? uid,
  }) async {
    _assertInitialized();

    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) {
      throw StateError('Tidak ada user Firebase yang sedang login.');
    }

    final data = account.toMap()
      ..remove('password')
      ..addAll({
        'uid': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

    await _firestore.collection('users').doc(userId).set(
          data,
          SetOptions(merge: true),
        );
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(
    String uid,
  ) async {
    _assertInitialized();
    return _firestore.collection('users').doc(uid).get();
  }

  static void _assertInitialized() {
    if (!FirebaseService.isInitialized) {
      throw StateError(
        'Firebase belum aktif. Jalankan flutterfire configure dan pastikan '
        'lib/firebase_options.dart berisi konfigurasi project Firebase.',
      );
    }
  }
}
