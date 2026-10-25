import 'dart:io';
import 'dart:typed_data';

import 'package:arabic_ocr/models/scan.dart';
import 'package:arabic_ocr/services/history_store.dart';
import 'package:arabic_ocr/services/model_store.dart';
import 'package:arabic_ocr/services/ocr_backend.dart';
import 'package:arabic_ocr/services/page_loader.dart';
import 'package:arabic_ocr/services/scan_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nuqta_engine/nuqta_engine.dart';

class FakeDownloader implements ModelDownloader {
  FakeDownloader({this.fail = false, this.wrongSize = false});
  final bool fail;
  final bool wrongSize;
  final downloaded = <String>[];

  @override
  Future<void> download(
    ModelFileSpec file,
    Directory dir, {
    required bool wifiOnly,
    required void Function(double progress) onProgress,
    required void Function(bool paused) onPaused,
  }) async {
    onProgress(0.5);
    if (fail) throw Exception('network down');
    final f = File('${dir.path}/${file.name}');
    final raf = await f.open(mode: FileMode.write);
    await raf.writeFrom('GGUF'.codeUnits);
    await raf.truncate(wrongSize ? 1000 : file.size);
    await raf.close();
    downloaded.add(file.name);
    onProgress(1);
  }

  @override
  Future<void> cancel() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
}

/// Returns a small white page for any source.
class FakeLoader extends PageLoader {
  int loads = 0;
  @override
  Future<PreparedImage> load(
    PageSource source, {
    required double megapixels,
    int quarterTurns = 0,
  }) async {
    loads++;
    if (source is FilePageSource && source.path == 'missing.jpg') {
      throw const PageLoadException(PageLoadError.missingFile);
    }
    return PreparedImage(Uint8List(8 * 8 * 4)..fillRange(0, 256, 255), 8, 8);
  }
}

void main() {
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('ocr_test'));
  tearDown(() async => tmp.delete(recursive: true));

  group('ModelStore', () {
    test('downloads both files, verifies them and loads the engine', () async {
      final dl = FakeDownloader();
      final backend = DemoBackend(loadDelay: Duration.zero);
      final store = ModelStore(
        backend: backend,
        downloader: dl,
        baseDir: () async => tmp,
      );
      await store.init();
      expect(store.status, ModelStatus.missing);
      final seen = <double>[];
      store.addListener(() => seen.add(store.progress));
      await store.download();
      expect(dl.downloaded, [
        'nuqta-ocr-0.8b-Q4_K_M.gguf',
        'nuqta-ocr-0.8b-mmproj-f16.gguf',
      ]);
      expect(store.status, ModelStatus.ready);
      expect(backend.isLoaded, isTrue);
      expect(store.progress, 1);
      // progress is weighted by file size and never goes backwards
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i], greaterThanOrEqualTo(seen[i - 1]));
      }
      expect(await store.bytesOnDisk(), ModelStore.totalBytes);
    });

    test('a later init finds the files and only loads', () async {
      final dl = FakeDownloader();
      await ModelStore(
        backend: DemoBackend(),
        downloader: dl,
        baseDir: () async => tmp,
      ).download();
      final dl2 = FakeDownloader();
      final store = ModelStore(
        backend: DemoBackend(loadDelay: Duration.zero),
        downloader: dl2,
        baseDir: () async => tmp,
      );
      await store.init();
      expect(store.status, ModelStatus.ready);
      expect(dl2.downloaded, isEmpty);
    });

    test('a wrong-size file is an error, a failed download too', () async {
      final store = ModelStore(
        backend: DemoBackend(),
        downloader: FakeDownloader(wrongSize: true),
        baseDir: () async => tmp,
      );
      await store.download();
      expect(store.status, ModelStatus.error);
      expect(store.error, ModelError.verify);

      final failing = ModelStore(
        backend: DemoBackend(),
        downloader: FakeDownloader(fail: true),
        baseDir: () async => tmp,
      );
      await failing.download();
      expect(failing.error, ModelError.download);
    });

    test('imports picked files by size and GGUF magic', () async {
      final src = Directory('${tmp.path}/picked')..createSync();
      Future<String> make(String name, int size, {bool gguf = true}) async {
        final f = File('${src.path}/$name');
        final raf = await f.open(mode: FileMode.write);
        await raf.writeFrom((gguf ? 'GGUF' : 'NOPE').codeUnits);
        await raf.truncate(size);
        await raf.close();
        return f.path;
      }

      final store = ModelStore(
        backend: DemoBackend(loadDelay: Duration.zero),
        downloader: FakeDownloader(),
        baseDir: () async => tmp,
      );
      final unknown = await store.importFiles([
        await make('a.gguf', ModelStore.model.size),
        await make('b.gguf', ModelStore.mmproj.legacySize!),
        await make('notes.gguf', 1234),
        await make('fake.bin', ModelStore.model.size, gguf: false),
      ]);
      expect(unknown, ['notes.gguf', 'fake.bin']);
      expect(store.status, ModelStatus.ready);
      await store.delete();
      expect(store.status, ModelStatus.missing);
      expect(await store.bytesOnDisk(), 0);
    });
  });

  group('HistoryStore', () {
    test('saves, reloads with relative image paths, deletes', () async {
      final h = HistoryStore(baseDir: () async => tmp);
      await h.load();
      final scan = Scan(
        id: 's1',
        createdAt: DateTime(2026, 10, 25, 9),
        mode: NuqtaMode.markdown,
        quality: ReadQuality.fast,
        title: 'كتاب',
        pages: [
          ScanPage(
            id: 'p1',
            source: const PdfPageSource('/x/book.pdf', 3),
            text: '# عنوان',
          ),
        ],
      );
      scan.pages.first
        ..imagePath = await h.savePageImage(
          scan,
          scan.pages.first,
          Uint8List.fromList([1, 2, 3]),
        )
        ..status = PageStatus.done;
      await h.save(scan);

      final raw = File('${tmp.path}/scans/s1/scan.json').readAsStringSync();
      expect(raw, contains('"imagePath":"p1.jpg"'));

      final h2 = HistoryStore(baseDir: () async => tmp);
      await h2.load();
      final back = h2.scans.single;
      expect(back.title, 'كتاب');
      expect(back.mode, NuqtaMode.markdown);
      expect(back.quality, ReadQuality.fast);
      final page = back.pages.single;
      expect((page.source as PdfPageSource).index, 3);
      expect(page.status, PageStatus.done);
      expect(File(page.imagePath!).readAsBytesSync(), [1, 2, 3]);
      expect(back.document.pages.single.blocks.single, isA<Object>());

      await h2.delete(back);
      expect(h2.scans, isEmpty);
      expect(Directory('${tmp.path}/scans/s1').existsSync(), isFalse);
    });

    test('an interrupted page is saved as queued', () {
      final p = ScanPage(
        id: 'p',
        source: const AssetPageSource('a'),
        status: PageStatus.writing,
      );
      expect(p.toJson()['status'], 'queued');
    });
  });

  group('ScanRunner', () {
    Scan newScan(
      List<PageSource> sources, {
      NuqtaMode mode = NuqtaMode.asWritten,
    }) => Scan(
      id: 'run',
      createdAt: DateTime.now(),
      mode: mode,
      quality: ReadQuality.accurate,
      pages: [
        for (var i = 0; i < sources.length; i++)
          ScanPage(id: 'p$i', source: sources[i]),
      ],
    );

    ScanRunner runner(
      HistoryStore h, {
      OcrBackend? backend,
      FakeLoader? loader,
    }) => ScanRunner(
      backend:
          backend ??
          DemoBackend(readDelay: Duration.zero, pieceDelay: Duration.zero),
      loader: loader ?? FakeLoader(),
      history: h,
      keepHistory: () => true,
      pauseInBackground: false,
      useWakelock: false,
    );

    testWidgets('reads every page, streams text and saves the scan', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final h = HistoryStore(baseDir: () async => tmp);
        final r = runner(h);
        final scan = newScan(const [
          AssetPageSource('a'),
          AssetPageSource('b'),
        ]);
        final statuses = <PageStatus>{};
        r.addListener(() {
          final p = r.currentPage;
          if (p != null) statuses.add(p.status);
        });
        await r.run(scan);
        expect(scan.pages.map((p) => p.status), everyElement(PageStatus.done));
        expect(
          scan.pages.first.text,
          DemoBackend.demoTexts[NuqtaMode.asWritten],
        );
        expect(
          statuses,
          containsAll([PageStatus.preparing, PageStatus.writing]),
        );
        expect(scan.pages.first.tokens, greaterThan(0));
        // page images are stored with the scan
        await Future<void>.delayed(const Duration(milliseconds: 500));
        expect(scan.pages.first.imagePath, isNotNull);
        expect(h.scans.single.id, 'run');
        r.dispose();
      });
    });

    testWidgets(
      'a page that cannot be loaded fails without stopping the rest',
      (tester) async {
        await tester.runAsync(() async {
          final r = runner(HistoryStore(baseDir: () async => tmp));
          final scan = newScan(const [
            FilePageSource('missing.jpg'),
            AssetPageSource('b'),
          ]);
          await r.run(scan);
          expect(scan.pages[0].status, PageStatus.failed);
          expect(scan.pages[0].error, 'missingFile');
          expect(scan.pages[1].status, PageStatus.done);
          r.dispose();
        });
      },
    );

    testWidgets('cancelAll stops the current page and cancels the rest', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final r = runner(
          HistoryStore(baseDir: () async => tmp),
          backend: DemoBackend(
            readDelay: Duration.zero,
            pieceDelay: const Duration(milliseconds: 20),
          ),
        );
        final scan = newScan(const [
          AssetPageSource('a'),
          AssetPageSource('b'),
          AssetPageSource('c'),
        ]);
        final done = r.run(scan);
        await Future<void>.delayed(const Duration(milliseconds: 80));
        await r.cancelAll();
        await done;
        expect(scan.pages[0].status, PageStatus.cancelled);
        expect(scan.pages[0].text, isNotEmpty);
        expect(
          scan.pages.skip(1).map((p) => p.status),
          everyElement(PageStatus.cancelled),
        );
        expect(r.isRunning, isFalse);
        r.dispose();
      });
    });

    testWidgets('retry reads a page again', (tester) async {
      await tester.runAsync(() async {
        final loader = FakeLoader();
        final r = runner(
          HistoryStore(baseDir: () async => tmp),
          loader: loader,
        );
        final scan = newScan(const [
          AssetPageSource('a'),
        ], mode: NuqtaMode.markdown);
        await r.run(scan);
        await r.retry(scan, scan.pages.single);
        expect(loader.loads, 2);
        expect(scan.pages.single.status, PageStatus.done);
        expect(scan.document.hasTables, isTrue);
        r.dispose();
      });
    });
  });

  group('PageLoader', () {
    testWidgets('applies EXIF orientation and keeps small crops at size', (
      tester,
    ) async {
      await tester.runAsync(() async {
        // 200x100 landscape pixels tagged "rotate 90° clockwise to view"
        final src = img.Image(width: 200, height: 100)
          ..clear(img.ColorRgb8(255, 0, 0));
        img.fillRect(
          src,
          x1: 0,
          y1: 0,
          x2: 19,
          y2: 99,
          color: img.ColorRgb8(0, 0, 255),
        );
        src.exif.imageIfd.orientation = 6;
        final f = File('${tmp.path}/rotated.jpg')
          ..writeAsBytesSync(img.encodeJpg(src));
        final out = await PageLoader().load(
          FilePageSource(f.path),
          megapixels: 2.4,
        );
        expect((out.width, out.height), (100, 200));
        // the blue left edge is now the top edge
        final top = out.rgba.sublist(50 * 4, 50 * 4 + 4);
        expect(top[2], greaterThan(200));
        expect(top[0], lessThan(60));
      });
    });

    testWidgets('scales a page photo to the target size', (tester) async {
      await tester.runAsync(() async {
        final src = img.Image(width: 1500, height: 2000)
          ..clear(img.ColorRgb8(250, 250, 250));
        final f = File('${tmp.path}/page.png')
          ..writeAsBytesSync(img.encodePng(src));
        final out = await PageLoader().load(
          FilePageSource(f.path),
          megapixels: 1.0,
        );
        expect(out.width * out.height, closeTo(1e6, 4000));
        expect(out.rgba.length, out.width * out.height * 4);
      });
    });

    test('rotate turns pixels clockwise', () {
      // 2x1: red, green
      final im = PreparedImage(
        Uint8List.fromList([255, 0, 0, 255, 0, 255, 0, 255]),
        2,
        1,
      );
      final r1 = PageLoader.rotate(im, 1);
      expect((r1.width, r1.height), (1, 2));
      expect(r1.rgba.sublist(0, 4), [255, 0, 0, 255]); // red on top
      final r2 = PageLoader.rotate(im, 2);
      expect(r2.rgba.sublist(0, 4), [0, 255, 0, 255]); // green first
      final r3 = PageLoader.rotate(im, 3);
      expect(r3.rgba.sublist(0, 4), [0, 255, 0, 255]); // green on top
    });

    test('bgra to rgba swaps red and blue', () {
      expect(PageLoader.bgraToRgba(Uint8List.fromList([1, 2, 3, 4])), [
        3,
        2,
        1,
        4,
      ]);
    });

    test('a stored page preview is a JPEG', () async {
      final jpeg = await PageLoader.encodePreview(
        PreparedImage(Uint8List(16 * 16 * 4)..fillRange(0, 1024, 200), 16, 16),
      );
      expect(jpeg.sublist(0, 2), [0xFF, 0xD8]);
    });
  });
}
