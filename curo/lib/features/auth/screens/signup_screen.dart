import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/curo_button.dart';
import '../../../core/widgets/curo_input_field.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms of Service.')),
      );
      return;
    }
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.s32),

                // Logo
                _AuthLogo(),
                const SizedBox(height: AppSpacing.s20),

                // Title
                Text('Join CURO 👋', style: AppTextStyles.h1),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Create your health account in 30 seconds',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s32),

                // Full Name
                CuroInputField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.name,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: AppSpacing.s16),

                // Phone
                _PhoneInputField(controller: _phoneController),
                const SizedBox(height: AppSpacing.s16),

                // Password
                CuroInputField(
                  label: 'Password',
                  hint: 'Create a strong password',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Password must be 8+ characters'
                      : null,
                ),
                const SizedBox(height: AppSpacing.s8),
                Row(
                  children: [
                    const Icon(Icons.check_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      'Passwords must be 8+ characters',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s20),

                // Terms checkbox
                GestureDetector(
                  onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (v) =>
                              setState(() => _agreedToTerms = v ?? false),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(
                              color: AppColors.border, width: 1.5),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'I understand and agree to the ',
                            style: AppTextStyles.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.primary,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),

                // Security note
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      'Your data is encrypted and secure',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s24),

                // Create Account button
                CuroButton(
                  label: 'Create Account',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
                const SizedBox(height: AppSpacing.s24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: Text(
                        'Log in',
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
    );
  }
}

// ── Shared auth widgets ────────────────────────────────────────────────────────

class _AuthLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Text(
          'c',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _PhoneInputField extends StatelessWidget {
  const _PhoneInputField({required this.controller});
  final TextEditingController controller;

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: BorderSide(color: color, width: 1.5),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Phone Number', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.s8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofillHints: const [AutofillHints.telephoneNumberNational],
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '3XX XXX XXXX',
            hintStyle: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
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
                  const Text('🇵🇰', style: TextStyle(fontSize: 18, height: 1.2)),
                  const SizedBox(width: AppSpacing.s4),
                  Text(
                    '+92',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            constraints: const BoxConstraints(minHeight: 52),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16, vertical: 14),
            filled: true,
            fillColor: AppColors.surface,
            border: _border(AppColors.border),
            enabledBorder: _border(AppColors.border),
            focusedBorder: _border(AppColors.primary),
            errorBorder: _border(AppColors.danger),
            focusedErrorBorder: _border(AppColors.danger),
            errorStyle:
                AppTextStyles.caption.copyWith(color: AppColors.danger),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Phone number is required';
            if (v.length < 10) return 'Enter a valid Pakistani number';
            return null;
          },
        ),
      ],
    );
  }
}
