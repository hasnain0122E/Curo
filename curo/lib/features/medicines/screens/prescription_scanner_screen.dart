import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/gemini_service.dart';
import '../providers/medicine_provider.dart';

class PrescriptionScannerScreen extends ConsumerStatefulWidget {
  const PrescriptionScannerScreen({super.key});

  @override
  ConsumerState<PrescriptionScannerScreen> createState() =>
      _PrescriptionScannerScreenState();
}

class _PrescriptionScannerScreenState
    extends ConsumerState<PrescriptionScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanLine;
  late Animation<double> _scanAnim;

  // Shared frame geometry (fraction of screen)
  static const _frameLeft = 0.08;
  static const _frameRight = 0.92;
  static const _frameTop = 0.20;
  static const _frameBottom = 0.72;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _scanLine = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLine, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _scanLine.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null || !mounted) return;
    await _scanAndNavigate(await picked.readAsBytes());
  }

  Future<void> _pickFromGallery() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    await _scanAndNavigate(await picked.readAsBytes());
  }

  Future<void> _scanAndNavigate(Uint8List bytes) async {
    if (!mounted) return;
    // Show scanning state while Gemini processes the image
    ref.read(medicineProvider.notifier).loadMockScanResults();

    final names = await GeminiService.scanPrescription(bytes);
    if (!mounted) return;

    await ref.read(medicineProvider.notifier).loadScannedFromFirebase(
          names.isNotEmpty ? names : ['Amoxicillin', 'Metformin'],
        );
    if (!mounted) return;
    context.push(AppRoutes.medicineResults);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hasTorch = ref.watch(medicineProvider.select((s) => s.hasTorch));

    final frameRect = Rect.fromLTRB(
      size.width * _frameLeft,
      size.height * _frameTop,
      size.width * _frameRight,
      size.height * _frameBottom,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated dark camera background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.1),
                radius: 1.2,
                colors: [Color(0xFF1A2530), Color(0xFF050A0E)],
              ),
            ),
          ),

          // Scan overlay + corner brackets
          AnimatedBuilder(
            animation: _scanAnim,
            builder: (_, _) => CustomPaint(
              size: Size(size.width, size.height),
              painter: _ScanOverlayPainter(
                frameRect: frameRect,
                scanProgress: _scanAnim.value,
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text('CURO',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'SCANNER',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hint pill — just above frame
          Positioned(
            top: frameRect.top - 44,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(AppRadius.r24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.crop_free_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      'Align prescription within the frame',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s48, vertical: AppSpacing.s24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Torch
                        GestureDetector(
                          onTap: () =>
                              ref.read(medicineProvider.notifier).toggleTorch(),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              hasTorch
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: hasTorch
                                  ? const Color(0xFFFCD34D)
                                  : Colors.white,
                              size: 22,
                            ),
                          ),
                        ),

                        // Capture button
                        GestureDetector(
                          onTap: _capture,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 3),
                            ),
                            child: Center(
                              child: Container(
                                width: 62,
                                height: 62,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    color: AppColors.primary, size: 28),
                              ),
                            ),
                          ),
                        ),

                        // Gallery
                        GestureDetector(
                          onTap: _pickFromGallery,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.photo_library_outlined,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Enter manually link
                  GestureDetector(
                    onTap: () {
                      ref.read(medicineProvider.notifier).loadMockScanResults();
                      context.push(AppRoutes.medicineResults);
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.s16),
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.white54),
                          children: [
                            const TextSpan(text: 'Having trouble? '),
                            TextSpan(
                              text: 'Enter manually.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overlay Painter ───────────────────────────────────────────────────────────

class _ScanOverlayPainter extends CustomPainter {
  const _ScanOverlayPainter({
    required this.frameRect,
    required this.scanProgress,
  });

  final Rect frameRect;
  final double scanProgress;

  @override
  void paint(Canvas canvas, Size size) {
    // Dark overlay outside frame
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutout = Path()..addRect(frameRect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, cutout),
      overlayPaint,
    );

    // Corner brackets
    const cornerLen = 26.0;
    final bracketPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(frameRect.topLeft,
        frameRect.topLeft + const Offset(cornerLen, 0), bracketPaint);
    canvas.drawLine(frameRect.topLeft,
        frameRect.topLeft + const Offset(0, cornerLen), bracketPaint);
    // Top-right
    canvas.drawLine(frameRect.topRight,
        frameRect.topRight + const Offset(-cornerLen, 0), bracketPaint);
    canvas.drawLine(frameRect.topRight,
        frameRect.topRight + const Offset(0, cornerLen), bracketPaint);
    // Bottom-left
    canvas.drawLine(frameRect.bottomLeft,
        frameRect.bottomLeft + const Offset(cornerLen, 0), bracketPaint);
    canvas.drawLine(frameRect.bottomLeft,
        frameRect.bottomLeft + const Offset(0, -cornerLen), bracketPaint);
    // Bottom-right
    canvas.drawLine(frameRect.bottomRight,
        frameRect.bottomRight + const Offset(-cornerLen, 0), bracketPaint);
    canvas.drawLine(frameRect.bottomRight,
        frameRect.bottomRight + const Offset(0, -cornerLen), bracketPaint);

    // Animated scan line
    final scanY =
        frameRect.top + frameRect.height * scanProgress;
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0),
          AppColors.primary.withValues(alpha: 0.7),
          AppColors.primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(
          frameRect.left, scanY - 1, frameRect.width, 2));
    canvas.drawLine(
      Offset(frameRect.left + 4, scanY),
      Offset(frameRect.right - 4, scanY),
      linePaint..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter old) =>
      old.scanProgress != scanProgress;
}
