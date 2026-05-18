import 'package:curo/core/widgets/curo_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _wrap({int index = 0, ValueChanged<int>? onTap}) => MaterialApp(
      home: Scaffold(
        body: const SizedBox.shrink(),
        bottomNavigationBar: CuroBottomNavBar(
          currentIndex: index,
          onTap: onTap ?? (_) {},
        ),
      ),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // ── labels ─────────────────────────────────────────────────────────────────

  group('CuroBottomNavBar labels', () {
    testWidgets('shows all 5 navigation labels', (tester) async {
      await tester.pumpWidget(_wrap());

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Labs'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Medicines'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });
  });

  // ── item count ─────────────────────────────────────────────────────────────

  group('CuroBottomNavBar item count', () {
    testWidgets('renders exactly 5 items', (tester) async {
      await tester.pumpWidget(_wrap());

      // Each item is an Expanded in the Row
      final row = tester.widget<Row>(find.byType(Row).last);
      expect(row.children.whereType<Expanded>().length, 5);
    });
  });

  // ── active state ───────────────────────────────────────────────────────────

  group('CuroBottomNavBar active item', () {
    testWidgets('active item label has bold font weight', (tester) async {
      // Index 0 = Home
      await tester.pumpWidget(_wrap(index: 0));
      await tester.pump();

      final homeText = tester.widget<Text>(find.text('Home'));
      expect(homeText.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('inactive items do not have bold font weight', (tester) async {
      await tester.pumpWidget(_wrap(index: 0));
      await tester.pump();

      final labsText = tester.widget<Text>(find.text('Labs'));
      expect(labsText.style?.fontWeight, FontWeight.w400);
    });

    testWidgets('active tab indicator has non-zero width', (tester) async {
      await tester.pumpWidget(_wrap(index: 1));
      await tester.pump(); // settle animation

      // AnimatedContainers: active one has width 24, inactive have width 0
      final containers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .where((c) => c.constraints?.maxHeight == 3)
          .toList();

      // The second container (Labs, index 1) should have width 24
      expect(containers[1].constraints?.maxWidth, 24.0);
      // All others should be 0
      for (var i = 0; i < containers.length; i++) {
        if (i != 1) {
          expect(containers[i].constraints?.maxWidth, 0.0);
        }
      }
    });
  });

  // ── tap callback ───────────────────────────────────────────────────────────

  group('CuroBottomNavBar tap callback', () {
    testWidgets('fires onTap with correct index when tab is tapped',
        (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(_wrap(onTap: (i) => tappedIndex = i));

      await tester.tap(find.text('Labs'));
      expect(tappedIndex, 1);
    });

    testWidgets('onTap fires with index 0 for Home', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(_wrap(index: 2, onTap: (i) => tappedIndex = i));

      await tester.tap(find.text('Home'));
      expect(tappedIndex, 0);
    });

    testWidgets('onTap fires with index 4 for Profile', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(_wrap(onTap: (i) => tappedIndex = i));

      await tester.tap(find.text('Profile'));
      expect(tappedIndex, 4);
    });

    testWidgets('onTap fires with index 3 for Medicines', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(_wrap(onTap: (i) => tappedIndex = i));

      await tester.tap(find.text('Medicines'));
      expect(tappedIndex, 3);
    });
  });

  // ── icon switching ─────────────────────────────────────────────────────────

  group('CuroBottomNavBar icon switching', () {
    testWidgets('active tab uses filled home icon', (tester) async {
      await tester.pumpWidget(_wrap(index: 0));
      await tester.pump();

      // Home is active — should show filled rounded icon
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    });

    testWidgets('inactive tabs use outline icons', (tester) async {
      await tester.pumpWidget(_wrap(index: 0));
      await tester.pump();

      // Labs, Reports, Medicines, Profile are inactive — outline icons
      expect(find.byIcon(Icons.science_outlined), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });
  });
}
