import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository({required FirebaseAuth auth, required FirebaseFirestore firestore})
      : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> sendOtp(
    String phone, {
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException error) onFailed,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        // Auto-verified on some Android devices — sign in directly
        await _auth.signInWithCredential(credential);
        onAutoVerified?.call(credential);
      },
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> verifyOtp(
      String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final result = await _auth.signInWithCredential(credential);
    // Create Firestore user document on first sign-in
    if (result.additionalUserInfo?.isNewUser == true) {
      await _createUserDocument(result.user!);
    }
    return result;
  }

  Future<void> _createUserDocument(User user) async {
    final doc = UserModel(
      uid: user.uid,
      phone: user.phoneNumber ?? '',
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(doc.toFirestore(), SetOptions(merge: true));
  }

  Stream<UserModel?> watchUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .withConverter<UserModel>(
          fromFirestore: (snap, _) => UserModel.fromFirestore(snap),
          toFirestore: (model, _) => model.toFirestore(),
        )
        .snapshots()
        .map((snap) => snap.data());
  }

  Future<void> updateUserProfile(
      String uid, {String? name, String? email}) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'email': email,
    }..removeWhere((_, v) => v == null));
  }

  Future<void> signOut() => _auth.signOut();
}
