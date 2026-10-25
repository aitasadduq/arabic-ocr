// UI screenshots at several device sizes, written as golden PNGs.
//
//   SCREENSHOTS=1 flutter test test/screenshots_test.dart --update-goldens
//
// The PNGs land in test/goldens/ (not committed; CI uploads them).
import 'dart:io';

import 'package:arabic_ocr/app.dart';
import 'package:arabic_ocr/app_scope.dart';
import 'package:arabic_ocr/services/ocr_backend.dart';
import 'package:arabic_ocr/models/scan.dart';
import 'package:arabic_ocr/ui/screens/review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuqta_engine/nuqta_engine.dart';

import 'support/fakes.dart';

/// Logical sizes. The iPhone Duo figures are derived from Apple's announced
/// panels (5.4" 1398x2034 and 7.6" 1878x2670) at 3x.
const devices = <String, Size>{
  'phone': Size(393, 852),
  'duo_cover': Size(466, 678),
  'duo_open': Size(626, 890),
  'duo_open_landscape': Size(890, 626),
  'tablet': Size(1024, 1366),
};

final _enabled = Platform.environment['SCREENSHOTS'] != null;

void main() {
  late Directory tmp;
  setUpAll(loadAppFonts);
  setUp(() async => tmp = await Directory.systemTemp.createTemp('shots'));
  tearDown(() async => tmp.delete(recursive: true));

  Future<void> setSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> precacheSamples(WidgetTester tester) async {
    final ctx = tester.element(find.byType(Navigator).first);
    await tester.runAsync(() async {
      for (final a in ['book', 'table', 'passport', 'old_book']) {
        if (!ctx.mounted) return;
        final img = AssetImage('assets/samples/$a.jpg');
        await precacheImage(img, ctx);
        // the sizes the thumbnails ask for
        for (final w in [160, 240, 480, 2000]) {
          if (!ctx.mounted) return;
          await precacheImage(ResizeImage(img, width: w), ctx);
        }
      }
    });
  }

  /// A few saved readings so the home screen has recents.
  Future<void> seedHistory(WidgetTester tester, AppServices s) async {
    await tester.runAsync(() async {
      final now = DateTime.now();
      for (final (i, (asset, mode, title)) in [
        (
          'assets/samples/table.jpg',
          NuqtaMode.markdown,
          'تقرير المؤسسات الخيرية',
        ),
        (
          'assets/samples/book.jpg',
          NuqtaMode.asWritten,
          'مغامرات الظربان جيمي',
        ),
        ('assets/samples/old_book.jpg', NuqtaMode.markdown, 'Old manuscript'),
      ].indexed) {
        await s.history.save(
          Scan(
            id: 'seed$i',
            createdAt: now.subtract(Duration(hours: i * 26)),
            mode: mode,
            quality: ReadQuality.accurate,
            title: title,
            pages: [
              ScanPage(
                id: 'p1',
                source: AssetPageSource(asset),
                status: PageStatus.done,
                text: DemoBackend.demoTexts[mode]!,
              ),
            ],
          ),
        );
      }
    });
  }

  /// The runner's last steps need the real event loop once.
  Future<void> finishReading(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pump(const Duration(milliseconds: 50));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  for (final MapEntry(key: device, value: size) in devices.entries) {
    for (final (lang, dark) in [('en', false), ('ar', true)]) {
      final tag = '${device}_${lang}_${dark ? 'dark' : 'light'}';

      testWidgets('home $tag', skip: !_enabled, (tester) async {
        await setSize(tester, size);
        final s = (await tester.runAsync(
          () => fakeServices(tmp, keepHistory: false),
        ))!;
        s.settings
          ..locale = Locale(lang)
          ..themeMode = dark ? ThemeMode.dark : ThemeMode.light;
        await seedHistory(tester, s);
        await tester.pumpWidget(ArabicOcrApp(services: s));
        await tester.runAsync(() => s.models.init());
        await tester.pumpAndSettle();
        await precacheSamples(tester);
        await tester.pumpAndSettle();
        await shot(tester, 'home_$tag');
      });

      testWidgets('result $tag', skip: !_enabled, (tester) async {
        await setSize(tester, size);
        final s = (await tester.runAsync(
          () => fakeServices(tmp, keepHistory: false),
        ))!;
        s.settings
          ..locale = Locale(lang)
          ..themeMode = dark ? ThemeMode.dark : ThemeMode.light;
        await tester.pumpWidget(ArabicOcrApp(services: s));
        await tester.runAsync(() => s.models.init());
        await tester.pumpAndSettle();
        await precacheSamples(tester);
        await tester.ensureVisible(find.byType(Image).at(1));
        await tester.tap(find.byType(Image).at(1)); // the table sample
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await finishReading(tester);
        await tester.pumpAndSettle();
        await shot(tester, 'result_$tag');
      });
    }
  }

  testWidgets('setup screen', skip: !_enabled, (tester) async {
    await setSize(tester, devices['phone']!);
    final s = (await tester.runAsync(
      () => fakeServices(tmp, modelReady: false),
    ))!;
    await tester.pumpWidget(ArabicOcrApp(services: s));
    await tester.runAsync(() => s.models.init());
    await tester.pumpAndSettle();
    await shot(tester, 'setup_phone_en_light');
  });

  testWidgets('review screen', skip: !_enabled, (tester) async {
    for (final device in ['phone', 'duo_open_landscape']) {
      await setSize(tester, devices[device]!);
      final s = (await tester.runAsync(() => fakeServices(tmp)))!;
      await tester.pumpWidget(
        ArabicOcrApp(
          services: s,
          home: const ReviewScreen(
            initial: [
              AssetPageSource('assets/samples/book.jpg'),
              AssetPageSource('assets/samples/table.jpg'),
              AssetPageSource('assets/samples/old_book.jpg'),
            ],
          ),
        ),
      );
      await precacheSamples(tester);
      await tester.pumpAndSettle();
      await shot(tester, 'review_${device}_en_light');
    }
  });

  testWidgets('export sheet and settings', skip: !_enabled, (tester) async {
    await setSize(tester, devices['phone']!);
    final s = (await tester.runAsync(
      () => fakeServices(tmp, keepHistory: false),
    ))!;
    s.settings.mode = NuqtaMode.markdown;
    await tester.pumpWidget(ArabicOcrApp(services: s));
    await tester.runAsync(() => s.models.init());
    await tester.pumpAndSettle();
    await precacheSamples(tester);
    await tester.tap(find.byType(Image).at(1));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await finishReading(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.ios_share_rounded));
    await tester.pumpAndSettle();
    await shot(tester, 'export_phone_en_light');

    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pop(); // the sheet
    await tester.pumpAndSettle();
    nav.pop(); // the reading
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await shot(tester, 'settings_phone_en_light');
  });
}
