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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = '+92${_phoneController.text.trim()}';
    ref.read(authProvider.notifier).setPhone(phone);
    await ref.read(authProvider.notifier).sendOtp();
    if (mounted) context.push(AppRoutes.otp, extra: phone);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Top cyan blob decoration
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -90,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.s48),

                    // Logo
                    _LoginLogo(),
                    const SizedBox(height: AppSpacing.s24),

                    // Title
                    Text('Welcome Back 👋', style: AppTextStyles.h1),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Log in to access your health dashboard',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s32),

                    // Phone input
                    _LoginPhoneField(controller: _phoneController),
                    const SizedBox(height: AppSpacing.s12),

                    // Security note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Your data is secure',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s24),

                    // Send OTP
                    CuroButton(
                      label: 'Send OTP',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _sendOtp,
                    ),
                    const SizedBox(height: AppSpacing.s24),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s12,
                          ),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: AppTextStyles.labelSmall,
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s20),

                    // Google button
                    _GoogleButton(),
                    const SizedBox(height: AppSpacing.s32),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New to CURO? ',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.signup),
                          child: Text(
                            'Sign up',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(
        child: Text(
          'c',
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _LoginPhoneField extends StatelessWidget {
  const _LoginPhoneField({required this.controller});
  final TextEditingController controller;

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.r12),
    borderSide: BorderSide(color: color, width: 1.5),
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      autofillHints: const [AutofillHints.telephoneNumberNational],
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: '3XX XXX XXXX',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              const Text('🇵🇰', style: TextStyle(fontSize: 16, height: 1.2)),
              const SizedBox(width: AppSpacing.s4),
              Text(
                '+92',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        constraints: const BoxConstraints(minHeight: 52),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: 14,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primary),
        errorBorder: _border(AppColors.danger),
        focusedErrorBorder: _border(AppColors.danger),
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.danger),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Phone number is required';
        if (v.length < 10) return 'Enter a valid Pakistani number';
        return null;
      },
    );
  }
}

class _GoogleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleG(),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    void drawArc(Color color, double start, double sweep) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.butt,
      );
    }

    const pi = 3.14159265;
    drawArc(const Color(0xFF4285F4), -pi / 4, pi / 2); // Blue (right)
    drawArc(const Color(0xFF34A853), pi / 4, pi / 2); // Green (bottom)
    drawArc(const Color(0xFFFBBC05), 3 * pi / 4, pi / 2); // Yellow (left)
    drawArc(const Color(0xFFEA4335), 5 * pi / 4, pi / 2); // Red (top)

    // Horizontal bar of G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), Offset(size.width, cy), barPaint);
  }

  @override
  bool shouldRepaint(_GoogleGPainter old) => false;
}
