import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_providers.dart';

class AuthState {
  const AuthState({
    this.phone = '',
    this.isLoading = false,
    this.error,
    this.verificationId,
  });

  final String phone;
  final bool isLoading;
  final String? error;
  final String? verificationId;

  AuthState copyWith({
    String? phone,
    bool? isLoading,
    String? error,
    String? verificationId,
  }) =>
      AuthState(
        phone: phone ?? this.phone,
        isLoading: isLoading ?? this.isLoading,
        error: error, // intentional: null clears the error
        verificationId: verificationId ?? this.verificationId,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void setPhone(String phone) => state = state.copyWith(phone: phone);

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
        state = state.copyWith(
          isLoading: false,
          error: _friendlyError(e),
        );
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
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();

  static String _friendlyError(FirebaseAuthException e) {
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

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
