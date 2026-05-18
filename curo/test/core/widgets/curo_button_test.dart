import 'package:curo/core/widgets/curo_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // ── variants ───────────────────────────────────────────────────────────────

  group('CuroButton variants', () {
    testWidgets('primary variant renders ElevatedButton', (tester) async {
      await tester.pumpWidget(_wrap(
        const CuroButton(label: 'Submit', variant: CuroButtonVariant.primary),
      ));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('secondary variant renders OutlinedButton', (tester) async {
      await tester.pumpWidget(_wrap(
        const CuroButton(label: 'Cancel', variant: CuroButtonVariant.secondary),
      ));
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('text variant renders TextButton', (tester) async {
      await tester.pumpWidget(_wrap(
        const CuroButton(label: 'Skip', variant: CuroButtonVariant.text),
      ));
      expect(find.byType(TextButton), findsOneWidget);
    });
  });

  // ── label ──────────────────────────────────────────────────────────────────

  group('CuroButton label', () {
    testWidgets('displays label text', (tester) async {
      await tester.pumpWidget(_wrap(
        const CuroButton(label: 'Book Test'),
      ));
      expect(find.text('Book Test'), findsOneWidget);
    });
  });

  // ── loading state ──────────────────────────────────────────────────────────

  group('CuroButton loading state', () {
    testWidgets('shows CircularProgressIndicator when isLoading = true',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const CuroButton(label: 'Submit', isLoading: true),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides label text when isLoading = true', (tester) async {
      await tester.pumpWidget(_wrap(
        const CuroButton(label: 'Submit', isLoading: true),
      ));
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('primary button is disabled when isLoading = true',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const CuroButton(
          label: 'Submit',
          isLoading: true,
          variant: CuroButtonVariant.primary,
        ),
      ));

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('secondary button is disabled when isLoading = true',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const CuroButton(
          label: 'Cancel',
          isLoading: true,
          variant: CuroButtonVariant.secondary,
        ),
      ));

      final button =
          tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
    });
  });

  // ── onPressed callback ─────────────────────────────────────────────────────

  group('CuroButton onPressed', () {
    testWidgets('fires callback on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        CuroButton(label: 'Go', onPressed: () => tapped = true),
      ));

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets('does not fire callback when isLoading = true', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        CuroButton(
          label: 'Go',
          isLoading: true,
          onPressed: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      expect(tapped, isFalse);
    });
  });

  // ── icon ───────────────────────────────────────────────────────────────────

  group('CuroButton icon', () {
    testWidgets('shows Icon widget when icon is provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const CuroButton(
          label: 'Scan',
          icon: Icons.camera_alt,
        ),
      ));

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
    });

    testWidgets('does not show Icon widget when no icon provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const CuroButton(label: 'Submit'),
      ));
      expect(find.byType(Icon), findsNothing);
    });
  });

  // ── width ──────────────────────────────────────────────────────────────────

  group('CuroButton width', () {
    testWidgets('expands to full width by default', (tester) async {
      await tester.pumpWidget(_wrap(
        const CuroButton(label: 'Full'),
      ));

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ElevatedButton),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, double.infinity);
    });

    testWidgets('respects custom width when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const CuroButton(label: 'Narrow', width: 120),
      ));

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ElevatedButton),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, 120);
    });
  });
}
