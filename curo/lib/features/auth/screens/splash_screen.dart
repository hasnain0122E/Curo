import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      context.go(user != null ? AppRoutes.home : AppRoutes.onboarding);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5DD6F5), Color(0xFF36BDF2), Color(0xFF179ED4)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(double.infinity, 110),
                painter: _WavePainter(),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CuroLogo(size: 72),
                  const SizedBox(height: 20),
                  Text(
                    'Curo',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Low-Cost Healthcare Near You',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
          size.width * 0.28, 0, size.width * 0.55, size.height * 0.4)
      ..quadraticBezierTo(
          size.width * 0.78, size.height * 0.7, size.width, size.height * 0.25)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => false;
}

// Shared logo widget used across auth screens
class _CuroLogo extends StatelessWidget {
  const _CuroLogo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Center(
        child: Text(
          'c',
          style: TextStyle(
            fontSize: size * 0.58,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
