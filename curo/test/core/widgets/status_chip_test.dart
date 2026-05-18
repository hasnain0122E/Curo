import 'package:curo/core/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // ── label ──────────────────────────────────────────────────────────────────

  group('StatusChip label', () {
    testWidgets('renders provided label text', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusChip(label: 'Normal', variant: StatusVariant.success),
      ));
      expect(find.text('Normal'), findsOneWidget);
    });

    testWidgets('renders label for danger variant', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusChip(label: 'High', variant: StatusVariant.danger),
      ));
      expect(find.text('High'), findsOneWidget);
    });
  });

  // ── color correctness ──────────────────────────────────────────────────────

  group('StatusChip colors', () {
    Future<Container> getContainer(
        WidgetTester tester, StatusVariant variant) async {
      await tester.pumpWidget(_wrap(
        StatusChip(label: 'X', variant: variant),
      ));
      return tester.widget<Container>(find.byType(Container).first);
    }

    testWidgets('success uses green background', (tester) async {
      final container = await getContainer(tester, StatusVariant.success);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0x1F22C55E));
    });

    testWidgets('warning uses amber background', (tester) async {
      final container = await getContainer(tester, StatusVariant.warning);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0x1FF59E0B));
    });

    testWidgets('danger uses red background', (tester) async {
      final container = await getContainer(tester, StatusVariant.danger);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0x1FEF4444));
    });

    testWidgets('medipoints uses yellow background', (tester) async {
      final container = await getContainer(tester, StatusVariant.medipoints);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0x26EAB308));
    });
  });

  // ── text color ─────────────────────────────────────────────────────────────

  group('StatusChip text color', () {
    Future<Text> getText(WidgetTester tester, StatusVariant variant) async {
      await tester.pumpWidget(
          _wrap(StatusChip(label: 'Test', variant: variant)));
      return tester.widget<Text>(find.text('Test'));
    }

    testWidgets('success foreground is dark green', (tester) async {
      final text = await getText(tester, StatusVariant.success);
      expect(text.style?.color, const Color(0xFF16A34A));
    });

    testWidgets('warning foreground is amber-dark', (tester) async {
      final text = await getText(tester, StatusVariant.warning);
      expect(text.style?.color, const Color(0xFFD97706));
    });

    testWidgets('danger foreground is dark red', (tester) async {
      final text = await getText(tester, StatusVariant.danger);
      expect(text.style?.color, const Color(0xFFDC2626));
    });

    testWidgets('medipoints foreground is dark yellow', (tester) async {
      final text = await getText(tester, StatusVariant.medipoints);
      expect(text.style?.color, const Color(0xFFCA8A04));
    });
  });

  // ── shape ─────────────────────────────────────────────────────────────────

  group('StatusChip shape', () {
    testWidgets('uses rounded rectangle with radius 20', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusChip(label: 'OK', variant: StatusVariant.success),
      ));
      final container =
          tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      final radius = decoration.borderRadius as BorderRadius;
      expect(radius, BorderRadius.circular(20));
    });
  });
}
