import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/ai_vision_service.dart';
import '../providers/lab_map_provider.dart';
import '../providers/lab_test_scan_provider.dart';

class LabTestScannerScreen extends ConsumerStatefulWidget {
  const LabTestScannerScreen({super.key});

  @override
  ConsumerState<LabTestScannerScreen> createState() =>
      _LabTestScannerScreenState();
}

class _LabTestScannerScreenState extends ConsumerState<LabTestScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanLine;
  late Animation<double> _scanAnim;

  bool _isScanning = false;
  String _processingLabel = '';
  Timer? _labelTimer;

  static const _frameLeft = 0.06;
  static const _frameRight = 0.94;
  static const _frameTop = 0.18;
  static const _frameBottom = 0.70;

  // Each step label is shown for ~2 s before cycling to the next.
  static const _kScanSteps = [
    'Optimising image…',
    'Analysing prescription…',
    'Matching nearby labs…',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _scanLine = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scanLine, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _labelTimer?.cancel();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _scanLine.dispose();
    super.dispose();
  }

  // ── Loading cycle helpers ──────────────────────────────────────────────────

  void _startLoadingCycle() {
    int idx = 0;
    _processingLabel = _kScanSteps[idx];
    _labelTimer?.cancel();
    _labelTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      idx = (idx + 1) % _kScanSteps.length;
      setState(() => _processingLabel = _kScanSteps[idx]);
    });
  }

  void _stopLoadingCycle() {
    _labelTimer?.cancel();
    _labelTimer = null;
  }

  // ── Image capture / pick ───────────────────────────────────────────────────

  Future<void> _capture() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;
    await _scanAndNavigate(picked.path);
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;
    await _scanAndNavigate(picked.path);
  }

  // ── Core scan pipeline ─────────────────────────────────────────────────────

  Future<void> _scanAndNavigate(String imagePath) async {
    if (!mounted || _isScanning) return;

    _startLoadingCycle();
    setState(() => _isScanning = true);

    try {
      // Groq vision call: grayscale + contrast boost → analyzeLabPrescription.
      final Map<String, dynamic> result = await AiVisionService.instance
          .analyzeLabPrescription(File(imagePath));

      // Parse detected_tests list from the JSON envelope.
      final raw = (result['detected_tests'] as List<dynamic>?) ?? [];
      final tests = raw
          .whereType<Map<String, dynamic>>()
          .map((e) => (e['test_name'] as String? ?? '').trim())
          .where((n) => n.isNotEmpty)
          .toList();

      if (!mounted) return;

      // Store names for the result screen display.
      ref.read(labTestScanProvider.notifier).setTests(tests);

      // Pre-wire the lab map filter so it instantly shows matching labs
      // when the user taps "Browse All Labs on Map" from the result screen.
      ref.read(labTestNamesFilterProvider.notifier).set(tests);
      ref.read(labFilterProvider.notifier).set(LabFilter.cheapest);

      context.push(AppRoutes.labTestScanResult);
    } on AiVisionException catch (e) {
      if (!mounted) return;
      ref.read(labTestScanProvider.notifier).setTests([]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.s16),
        ),
      );
      // Navigate to result screen so the empty state guides the user.
      context.push(AppRoutes.labTestScanResult);
    } catch (_) {
      if (!mounted) return;
      ref.read(labTestScanProvider.notifier).setTests([]);
      context.push(AppRoutes.labTestScanResult);
    } finally {
      _stopLoadingCycle();
      if (mounted) setState(() => _isScanning = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
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
          // Background gradient — green-tinted for lab context
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.1),
                radius: 1.2,
                colors: [Color(0xFF0D2117), Color(0xFF020804)],
              ),
            ),
          ),

          // Scan frame with animated line
          AnimatedBuilder(
            animation: _scanAnim,
            builder: (_, _) => CustomPaint(
              size: Size(size.width, size.height),
              painter: _LabScanOverlayPainter(
                frameRect: frameRect,
                scanProgress: _scanAnim.value,
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s8,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'CURO',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'LAB SCANNER',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hint above frame
          Positioned(
            top: frameRect.top - 44,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(AppRadius.r24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.biotech_outlined,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      'Align lab test prescription in frame',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s48,
                  vertical: AppSpacing.s24,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Spacer for visual symmetry with the gallery button
                    const SizedBox(width: 48),

                    // Shutter button
                    GestureDetector(
                      onTap: _isScanning ? null : _capture,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Color(0xFF22C55E),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Gallery picker
                    GestureDetector(
                      onTap: _isScanning ? null : _pickFromGallery,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Processing overlay — shown during API call
          if (_isScanning)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s32,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.s24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2117),
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          color: Color(0xFF22C55E),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Text(
                        _processingLabel,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        'AI-powered analysis in progress',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white54,
                        ),
                        textAlign: TextAlign.center,
                      ),
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

// ── Overlay Painter ───────────────────────────────────────────────────────────

class _LabScanOverlayPainter extends CustomPainter {
  const _LabScanOverlayPainter({
    required this.frameRect,
    required this.scanProgress,
  });

  final Rect frameRect;
  final double scanProgress;

  static const _scanColor = Color(0xFF22C55E);

  @override
  void paint(Canvas canvas, Size size) {
    // Dimmed overlay with frame cutout
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
      ..color = _scanColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      frameRect.topLeft,
      frameRect.topLeft + const Offset(cornerLen, 0),
      bracketPaint,
    );
    canvas.drawLine(
      frameRect.topLeft,
      frameRect.topLeft + const Offset(0, cornerLen),
      bracketPaint,
    );
    canvas.drawLine(
      frameRect.topRight,
      frameRect.topRight + const Offset(-cornerLen, 0),
      bracketPaint,
    );
    canvas.drawLine(
      frameRect.topRight,
      frameRect.topRight + const Offset(0, cornerLen),
      bracketPaint,
    );
    canvas.drawLine(
      frameRect.bottomLeft,
      frameRect.bottomLeft + const Offset(cornerLen, 0),
      bracketPaint,
    );
    canvas.drawLine(
      frameRect.bottomLeft,
      frameRect.bottomLeft + const Offset(0, -cornerLen),
      bracketPaint,
    );
    canvas.drawLine(
      frameRect.bottomRight,
      frameRect.bottomRight + const Offset(-cornerLen, 0),
      bracketPaint,
    );
    canvas.drawLine(
      frameRect.bottomRight,
      frameRect.bottomRight + const Offset(0, -cornerLen),
      bracketPaint,
    );

    // Animated scan line
    final scanY = frameRect.top + frameRect.height * scanProgress;
    final linePaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              _scanColor.withValues(alpha: 0),
              _scanColor.withValues(alpha: 0.7),
              _scanColor.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromLTWH(frameRect.left, scanY - 1, frameRect.width, 2),
          );
    canvas.drawLine(
      Offset(frameRect.left + 4, scanY),
      Offset(frameRect.right - 4, scanY),
      linePaint..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_LabScanOverlayPainter old) =>
      old.scanProgress != scanProgress;
}
