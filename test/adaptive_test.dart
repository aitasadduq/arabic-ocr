import 'dart:io';
import 'dart:ui';

import 'package:arabic_ocr/app.dart';
import 'package:arabic_ocr/models/scan.dart';
import 'package:arabic_ocr/ui/adaptive.dart';
import 'package:arabic_ocr/ui/screens/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuqta_engine/nuqta_engine.dart';

import 'support/fakes.dart';

void main() {
  test('window size classes', () {
    expect(WindowSize.of(393), WindowSize.compact); // phone
    expect(WindowSize.of(466), WindowSize.compact); // Duo cover
    expect(WindowSize.of(626), WindowSize.medium); // Duo open, portrait
    expect(WindowSize.of(890), WindowSize.expanded); // Duo open, landscape
  });

  group('AdaptiveSplit', () {
    Future<(Rect, Rect)> layout(
      WidgetTester tester, {
      TextDirection dir = TextDirection.ltr,
      List<DisplayFeature> features = const [],
      Axis axis = Axis.horizontal,
    }) async {
      tester.view.physicalSize = const Size(840, 600);
      tester.view.devicePixelRatio = 1;
      tester.view.displayFeatures = features;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: dir,
            child: AdaptiveSplit(
              axis: axis,
              initialFraction: 0.4,
              first: const ColoredBox(key: Key('first'), color: Colors.red),
              second: const ColoredBox(key: Key('second'), color: Colors.blue),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return (
        tester.getRect(find.byKey(const Key('first'))),
        tester.getRect(find.byKey(const Key('second'))),
      );
    }

    testWidgets('splits at the fraction without a hinge', (tester) async {
      final (a, b) = await layout(tester);
      expect(a.width, closeTo(336, 1)); // 40% of 840
      expect(b.left, greaterThan(a.right));
    });

    testWidgets('dragging the handle moves the split', (tester) async {
      final (a, _) = await layout(tester);
      await tester.drag(
        find.byType(GestureDetector).last,
        const Offset(100, 0),
      );
      await tester.pump();
      expect(
        tester.getRect(find.byKey(const Key('first'))).width,
        closeTo(a.width + 100, 2),
      );
    });

    testWidgets('panes go either side of a hinge', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTWH(410, 0, 20, 600),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );
      final (a, b) = await layout(tester, features: [hinge]);
      expect(a, const Rect.fromLTWH(0, 0, 410, 600));
      expect(b.left, 430);
      final (ra, rb) = await layout(
        tester,
        features: [hinge],
        dir: TextDirection.rtl,
      );
      // right to left: the first pane is on the right of the hinge
      expect(ra.left, 430);
      expect(rb.right, 410);
    });

    testWidgets('a flat fold is not a separator', (tester) async {
      const fold = DisplayFeature(
        bounds: Rect.fromLTWH(420, 0, 0, 600),
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureFlat,
      );
      final (a, _) = await layout(tester, features: [fold]);
      expect(a.width, closeTo(336, 1));
    });
  });

  group('result screen on a foldable', () {
    late Directory tmp;
    setUp(() async => tmp = await Directory.systemTemp.createTemp('fold'));
    tearDown(() async => tmp.delete(recursive: true));

    testWidgets(
      'unfolding shows the page beside the text and keeps the reading place',
      (tester) async {
        tester.view.devicePixelRatio = 3;
        tester.view.physicalSize = const Size(466, 678) * 3; // Duo cover
        addTearDown(tester.view.reset);
        final s = (await tester.runAsync(
          () => fakeServices(tmp, keepHistory: false),
        ))!;
        final long = List.generate(
          80,
          (i) => 'سطر رقم ${i + 1} من النص المقروء',
        ).join('\n');
        final scan = Scan(
          id: 'x',
          createdAt: DateTime(2026),
          mode: NuqtaMode.asWritten,
          quality: ReadQuality.accurate,
          title: 'Book',
          pages: [
            ScanPage(
              id: 'p1',
              source: const AssetPageSource('assets/samples/book.jpg'),
              status: PageStatus.done,
              text: long,
            ),
          ],
        );
        await tester.pumpWidget(
          ArabicOcrApp(
            services: s,
            home: ResultScreen(scan: scan),
          ),
        );
        await tester.pumpAndSettle();
        // folded: text only
        expect(find.byType(AdaptiveSplit), findsNothing);

        await tester.drag(find.byType(ListView).last, const Offset(0, -900));
        await tester.pumpAndSettle();
        final offset = tester
            .state<ScrollableState>(find.byType(Scrollable).last)
            .position
            .pixels;
        expect(offset, greaterThan(500));

        // unfold
        tester.view.physicalSize = const Size(890, 626) * 3;
        await tester.pumpAndSettle();
        expect(find.byType(AdaptiveSplit), findsOneWidget);
        expect(find.byType(InteractiveViewer), findsOneWidget);
        final after = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(SelectionArea),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(after.position.pixels, closeTo(offset, 1));

        // fold again: back to text only, same place
        tester.view.physicalSize = const Size(466, 678) * 3;
        await tester.pumpAndSettle();
        expect(find.byType(AdaptiveSplit), findsNothing);
        final folded = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(SelectionArea),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(folded.position.pixels, closeTo(offset, 1));
      },
    );
  });
}
