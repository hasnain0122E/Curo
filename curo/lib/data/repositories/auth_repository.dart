import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Email / Password ──────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmailPassword(
      String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> createAccountWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user!;
    await user.updateDisplayName('$firstName $lastName');
    await _upsertUserDocument(
      user,
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
    return result;
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled.');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    if (result.additionalUserInfo?.isNewUser == true) {
      final parts = (result.user?.displayName ?? '').split(' ');
      await _upsertUserDocument(
        result.user!,
        firstName: parts.isNotEmpty ? parts.first : '',
        lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
        email: result.user?.email ?? '',
      );
    }
    return result;
  }

  // ── Phone OTP (kept for optional use) ────────────────────────────────────

  Future<void> sendOtp(
    String phone, {
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException error) onFailed,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
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
    if (result.additionalUserInfo?.isNewUser == true) {
      await _upsertUserDocument(
        result.user!,
        phone: result.user?.phoneNumber,
      );
    }
    return result;
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Future<void> _upsertUserDocument(
    User user, {
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    final data = <String, dynamic>{
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (firstName != null && firstName.isNotEmpty) data['firstName'] = firstName;
    if (lastName != null && lastName.isNotEmpty) data['lastName'] = lastName;
    if (email != null && email.isNotEmpty) data['email'] = email;
    if (phone != null && phone.isNotEmpty) data['phone'] = phone;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
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

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
