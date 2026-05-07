import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/curo_button.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});
  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _otpLength = 6;
  static const _resendSeconds = 45;

  final _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  late Timer _timer;
  int _secondsLeft = _resendSeconds;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNodes[0].requestFocus());
  }

  void _startTimer() {
    _secondsLeft = _resendSeconds;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        setState(() => _canResend = true);
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _verify() async {
    final otp = _otp;
    if (otp.length < _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 6 digits.')),
      );
      return;
    }
    final ok = await ref.read(authProvider.notifier).verifyOtp(otp);
    if (ok && mounted) context.go(AppRoutes.home);
  }

  void _onBoxChanged(int index, String value) {
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _onBoxBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final phone = widget.phone;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.s16),

              // Back button
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.s24),

              // Title
              Text('Verify Your Number', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.s8),
              Text.rich(
                TextSpan(
                  text: 'We sent a 6-digit code to ',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                      text: phone,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Illustration
              _OtpIllustration(),
              const SizedBox(height: AppSpacing.s32),

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  _otpLength,
                  (i) => _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    onChanged: (v) => _onBoxChanged(i, v),
                    onBackspace: () => _onBoxBackspace(i),
                    isFilled: _controllers[i].text.isNotEmpty,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s20),

              // Resend timer / button
              Center(
                child: _canResend
                    ? GestureDetector(
                        onTap: () {
                          _timer.cancel();
                          _startTimer();
                          ref.read(authProvider.notifier).sendOtp();
                        },
                        child: Text(
                          'Resend OTP',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            'Resend in $_timerLabel',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.s32),

              // Verify button
              CuroButton(
                label: 'Verify & Continue',
                icon: Icons.arrow_forward_rounded,
                isLoading: isLoading,
                onPressed: isLoading ? null : _verify,
              ),
              const SizedBox(height: AppSpacing.s20),

              // Terms note
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'By continuing, you agree to CURO\'s ',
                    style: AppTextStyles.caption,
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.s32),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
    required this.isFilled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;
  final bool isFilled;

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: BorderSide(color: color, width: 1.5),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 54,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            onBackspace();
          }
        },
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor:
                isFilled ? AppColors.primary.withValues(alpha: 0.07) : AppColors.surface,
            border: _border(AppColors.border),
            enabledBorder: _border(
                isFilled ? AppColors.primary : AppColors.border),
            focusedBorder: _border(AppColors.primary),
            errorBorder: _border(AppColors.danger),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _OtpIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2ABDE8), Color(0xFF179ED4)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Faint ECG line
          CustomPaint(
            size: Size(double.infinity, 160),
            painter: _EcgPainter(),
          ),
          // Phone + lock icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_android_rounded,
                  color: Colors.white, size: 48),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final y = size.height / 2;
    path.moveTo(0, y);
    path.lineTo(size.width * 0.2, y);
    path.lineTo(size.width * 0.25, y - 30);
    path.lineTo(size.width * 0.30, y + 20);
    path.lineTo(size.width * 0.35, y - 50);
    path.lineTo(size.width * 0.40, y + 15);
    path.lineTo(size.width * 0.45, y);
    path.lineTo(size.width, y);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_EcgPainter old) => false;
}

