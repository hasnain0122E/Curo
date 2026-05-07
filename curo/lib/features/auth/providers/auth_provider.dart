import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  const AuthState({
    this.phone = '',
    this.isLoading = false,
    this.error,
  });

  final String phone;
  final bool isLoading;
  final String? error;

  AuthState copyWith({String? phone, bool? isLoading, String? error}) =>
      AuthState(
        phone: phone ?? this.phone,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void setPhone(String phone) => state = state.copyWith(phone: phone);

  Future<void> sendOtp() async {
    state = state.copyWith(isLoading: true, error: null);
    // TODO: replace with Firebase phone auth
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(isLoading: false);
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    // TODO: replace with Firebase credential verification
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(isLoading: false);
    return true;
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
