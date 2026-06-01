import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_providers.dart';

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.error,
    this.phone = '',
    this.verificationId,
  });

  final bool isLoading;
  final String? error;
  final String phone;
  final String? verificationId;

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? phone,
    String? verificationId,
  }) => AuthState(
    isLoading: isLoading ?? this.isLoading,
    error: error, // null clears the error
    phone: phone ?? this.phone,
    verificationId: verificationId ?? this.verificationId,
  );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void setPhone(String phone) => state = state.copyWith(phone: phone);
  void clearError() => state = state.copyWith();

  // ── Email / Password ──────────────────────────────────────────────────────

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmailPassword(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyEmailError(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .createAccountWithEmail(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
          );
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyEmailError(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Google ────────────────────────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final msg = e.toString();
      state = state.copyWith(
        isLoading: false,
        error: msg.contains('cancelled') ? null : 'Google sign-in failed.',
      );
      return false;
    }
  }

  // ── Phone OTP ─────────────────────────────────────────────────────────────

  Future<void> sendOtp() async {
    state = state.copyWith(isLoading: true);
    final repo = ref.read(authRepositoryProvider);
    await repo.sendOtp(
      state.phone,
      onCodeSent: (verificationId, _) {
        state = state.copyWith(
          isLoading: false,
          verificationId: verificationId,
        );
      },
      onFailed: (e) {
        state = state.copyWith(isLoading: false, error: _friendlyPhoneError(e));
      },
      onAutoVerified: (_) {
        state = state.copyWith(isLoading: false);
      },
    );
  }

  Future<bool> verifyOtp(String otp) async {
    final vid = state.verificationId;
    if (vid == null) {
      state = state.copyWith(error: 'Session expired. Please resend OTP.');
      return false;
    }
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(vid, otp);
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyPhoneError(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();

  // ── Error helpers ─────────────────────────────────────────────────────────

  static String _friendlyEmailError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'Something went wrong.';
    }
  }

  static String _friendlyPhoneError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Use +92 format.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-verification-code':
        return 'Incorrect OTP. Please try again.';
      case 'session-expired':
        return 'OTP expired. Please request a new one.';
      default:
        return e.message ?? 'Something went wrong.';
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
