// On-device tests (Android emulator, iOS simulator).
//
//   flutter test integration_test/app_test.dart -d <device>
//
// With --dart-define=E2E_MODEL=true the test also downloads the real model
// (765 MB) with the app's own downloader, loads it and reads a sample page.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:arabic_ocr/app.dart';
import 'package:arabic_ocr/app_scope.dart';
import 'package:arabic_ocr/core/document/document_parser.dart';
import 'package:arabic_ocr/core/document/ocr_document.dart';
import 'package:arabic_ocr/core/export/office_exporters.dart';
import 'package:arabic_ocr/models/scan.dart';
import 'package:arabic_ocr/services/model_store.dart';
import 'package:arabic_ocr/services/ocr_backend.dart';
import 'package:arabic_ocr/services/page_loader.dart';
import 'package:arabic_ocr/ui/screens/home_screen.dart';
import 'package:arabic_ocr/ui/screens/setup_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nuqta_engine/nuqta_engine.dart';
import 'package:path_provider/path_provider.dart';

const _e2eModel = bool.fromEnvironment('E2E_MODEL');

/// A one-page PDF with a black box in the top-left quarter (written by hand so
/// the test needs no PDF library).
Uint8List _tinyPdf() {
  const content = '0 0 0 rg 0 396 306 396 re f';
  final objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>',
    '<< /Length ${content.length} >>\nstream\n$content\nendstream',
  ];
  final b = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(b.length);
    b.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
  }
  final xref = b.length;
  b.write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
  for (final o in offsets) {
    b.write('${o.toString().padLeft(10, '0')} 00000 n \n');
  }
  b.write(
    'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n',
  );
  return Uint8List.fromList(latin1.encode(b.toString()));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the app starts on the model set-up screen', (tester) async {
    final services = await AppServices.create();
    await services.models.delete(); // a clean first run
    services.settings.setupSeen = false;
    await tester.pumpWidget(ArabicOcrApp(services: services));
    await tester.pumpAndSettle();
    expect(find.byType(SetupScreen), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    // reading needs the model: the app says so instead of failing
    await tester.ensureVisible(find.text('Table'));
    await tester.tap(find.text('Table'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Download the model first to read pages.'),
      findsOneWidget,
    );
  });

  testWidgets('pages decode on the device at the model size', (tester) async {
    final loader = PageLoader();
    final page = await loader.load(
      const AssetPageSource('assets/samples/book.jpg'),
      megapixels: NuqtaInputPolicy.fastMegapixels,
    );
    expect(page.width * page.height, closeTo(1e6, 5000));
    expect(page.rgba.length, page.width * page.height * 4);
    final turned = await loader.load(
      const AssetPageSource('assets/samples/book.jpg'),
      megapixels: NuqtaInputPolicy.fastMegapixels,
      quarterTurns: 1,
    );
    expect((turned.width, turned.height), (page.height, page.width));
    // stored page images are JPEG
    final jpeg = await PageLoader.encodePreview(page);
    expect(jpeg.sublist(0, 2), [0xFF, 0xD8]);
  });

  testWidgets('PDF pages render with PDFium at 200 dpi', (tester) async {
    final dir = await getTemporaryDirectory();
    final pdf = File('${dir.path}/tiny.pdf')..writeAsBytesSync(_tinyPdf());
    final loader = PageLoader();
    expect(await loader.pdfPageCount(pdf.path), 1);
    final img = await loader.load(PdfPageSource(pdf.path, 0), megapixels: 2.4);
    // a letter page is page-shaped: scaled to 2.4 MP
    expect(img.width * img.height, closeTo(2.4e6, 6000));
    int px(double fx, double fy) {
      final i =
          ((fy * img.height).toInt() * img.width + (fx * img.width).toInt()) *
          4;
      return img.rgba[i];
    }

    expect(px(0.25, 0.25), lessThan(40)); // inside the black box
    expect(px(0.75, 0.75), greaterThan(215)); // white paper
    await loader.closeAll();
  });

  testWidgets('exports are written on the device', (tester) async {
    final doc = OcrDocument([
      DocumentParser.parse(
        '# عنوان\n<table><tr><th>أ</th><td>١</td></tr></table>',
      ),
    ]);
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/t.docx')
      ..writeAsBytesSync(OfficeExporters.toDocx(doc));
    expect(f.lengthSync(), greaterThan(1000));
    expect(OfficeExporters.toXlsx(doc).sublist(0, 2), [0x50, 0x4B]); // zip
  });

  testWidgets(
    'downloads the model, loads it on the device and reads Arabic',
    skip: !_e2eModel,
    timeout: const Timeout(Duration(minutes: 40)),
    (tester) async {
      final backend = NuqtaBackend();
      final store = ModelStore(backend: backend);
      await store.init();
      if (!store.isReady) await store.download();
      expect(
        store.status,
        ModelStatus.ready,
        reason: '${store.error} ${store.errorDetail}',
      );
      expect(backend.isLoaded, isTrue);

      final page = await PageLoader().load(
        const AssetPageSource('assets/samples/book.jpg'),
        megapixels: NuqtaInputPolicy.fastMegapixels,
      );
      final job = backend.read(page, NuqtaMode.asWritten);
      final stages = <NuqtaStage>[];
      var pieces = 0;
      job.events.listen((e) {
        if (e is NuqtaStageEvent) stages.add(e.stage);
        if (e is NuqtaTextEvent && ++pieces == 40) job.cancel();
      });
      final r = await job.result;
      // ignore: avoid_print
      print(
        'device read: ${r.stats.imageTokens} image tokens, first words after '
        '${r.stats.firstTokenSeconds.toStringAsFixed(1)} s, '
        '${r.stats.tokensPerSecond.toStringAsFixed(1)} tok/s\n${r.text}',
      );
      expect(stages, contains(NuqtaStage.writing));
      expect(RegExp(r'[ء-ي]').hasMatch(r.text), isTrue);
      expect(r.status, NuqtaStatus.cancelled);
    },
  );
}
