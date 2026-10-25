import 'dart:io';

import 'package:arabic_ocr/app.dart';
import 'package:arabic_ocr/ui/screens/home_screen.dart';
import 'package:arabic_ocr/ui/screens/result_screen.dart';
import 'package:arabic_ocr/ui/screens/setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('app_test'));
  tearDown(() async => tmp.delete(recursive: true));

  testWidgets('first run without the model shows the set-up screen', (
    tester,
  ) async {
    final services = await tester.runAsync(
      () => fakeServices(tmp, modelReady: false),
    );
    await tester.pumpWidget(ArabicOcrApp(services: services!));
    await tester.runAsync(() => services.models.init());
    await tester.pumpAndSettle();
    expect(find.byType(SetupScreen), findsOneWidget);
    expect(find.text('Download and start'), findsOneWidget);
    await tester.ensureVisible(find.text('Not now'));
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    // the home screen still offers the download
    expect(find.text('Download the reading model'), findsOneWidget);
  });

  testWidgets('a sample is read and the table shows up formatted', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // history (real file IO) is covered by services_test
    final services = await tester.runAsync(
      () => fakeServices(tmp, keepHistory: false),
    );
    await tester.pumpWidget(ArabicOcrApp(services: services!));
    await tester.runAsync(() async {
      await services.models.init();
      await services.history.load();
    });
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Read Arabic pages'), findsOneWidget);

    await tester.ensureVisible(find.text('Table'));
    await tester.tap(find.text('Table'));
    // the page transition (no pumpAndSettle: the writing indicator animates)
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ResultScreen), findsOneWidget);
    // let the demo engine write the page
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    await tester.pumpAndSettle();
    expect(find.text('غير فعالة على الإطلاق'), findsOneWidget);
    expect(find.text('Copy table'), findsOneWidget);
    expect(services.runner.isRunning, isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('the app is usable in Arabic (RTL)', (tester) async {
    final services = await tester.runAsync(() => fakeServices(tmp));
    services!.settings.locale = const Locale('ar');
    await tester.pumpWidget(ArabicOcrApp(services: services));
    await tester.runAsync(() => services.models.init());
    await tester.pumpAndSettle();
    expect(find.text('اقرأ الصفحات العربية'), findsOneWidget);
    final dir = Directionality.of(tester.element(find.byType(HomeScreen)));
    expect(dir, TextDirection.rtl);
  });
}
