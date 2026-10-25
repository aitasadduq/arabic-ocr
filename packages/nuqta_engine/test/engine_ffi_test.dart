// Runs the real native engine through dart:ffi on the host.
//
//   NUQTA_ENGINE_LIB=/path/to/libnuqta_engine.so   (host CMake build of src/)
//   NUQTA_MODEL_DIR=/path/to/gguf                   (optional: real-model tests)
//
// Without NUQTA_ENGINE_LIB the tests are skipped.
@Timeout(Duration(minutes: 20))
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nuqta_engine/nuqta_engine.dart';

final _lib = Platform.environment['NUQTA_ENGINE_LIB'];
final _models = Platform.environment['NUQTA_MODEL_DIR'];

const _modelFile = 'nuqta-ocr-0.8b-Q4_K_M.gguf';
const _mmprojFile = 'nuqta-ocr-0.8b-mmproj-f16.gguf';

({List<int> rgba, int w, int h}) _fixture(
  String name, {
  double mp = NuqtaInputPolicy.accurateMegapixels,
}) {
  final decoded = img.decodeImage(
    File('test/fixtures/$name').readAsBytesSync(),
  )!;
  final size = NuqtaInputPolicy.targetSize(
    decoded.width,
    decoded.height,
    megapixels: mp,
  );
  final resized = img.copyResize(
    decoded,
    width: size.width,
    height: size.height,
    interpolation: img.Interpolation.average,
  );
  final rgba = resized
      .convert(numChannels: 4)
      .getBytes(order: img.ChannelOrder.rgba);
  return (rgba: rgba, w: resized.width, h: resized.height);
}

bool _hasArabic(String s) => RegExp(r'[؀-ۿ]').hasMatch(s);

void main() {
  final skipEngine = _lib == null ? 'NUQTA_ENGINE_LIB not set' : null;
  final skipModel =
      skipEngine ?? (_models == null ? 'NUQTA_MODEL_DIR not set' : null);

  group('engine without a model', skip: skipEngine, () {
    late NuqtaEngine engine;
    setUpAll(() => engine = NuqtaEngine(libraryPath: _lib));

    test('reports its version and threads', () {
      expect(engine.version, contains('5aeac37a'));
      expect(engine.defaultThreads, inInclusiveRange(2, 6));
      expect(engine.isLoaded, isFalse);
    });

    test('a missing model file fails the load with a message', () async {
      await expectLater(
        engine.load(
          modelPath: '/nope/model.gguf',
          mmprojPath: '/nope/mmproj.gguf',
        ),
        throwsA(
          isA<NuqtaException>().having(
            (e) => e.message,
            'message',
            contains('model'),
          ),
        ),
      );
      expect(engine.isLoaded, isFalse);
    });

    test('a read before load fails cleanly', () async {
      final job = engine.read(
        pixels: Uint8List(4 * 4 * 4),
        width: 4,
        height: 4,
        prompt: NuqtaMode.asWritten.prompt,
      );
      await expectLater(job.result, throwsA(isA<NuqtaException>()));
    });

    test('an invalid image is rejected', () async {
      final job = engine.read(
        pixels: Uint8List(16),
        width: 2,
        height: 2,
        channels: 2,
        prompt: 'x',
      );
      await expectLater(
        job.result,
        throwsA(
          isA<NuqtaException>().having(
            (e) => e.message,
            'message',
            'invalid image',
          ),
        ),
      );
    });
  });

  group('engine with the real model', skip: skipModel, () {
    late NuqtaEngine engine;
    setUpAll(() async {
      engine = NuqtaEngine(libraryPath: _lib);
      final sw = Stopwatch()..start();
      await engine.load(
        modelPath: '$_models/$_modelFile',
        mmprojPath: '$_models/$_mmprojFile',
      );
      // ignore: avoid_print
      print('model loaded in ${sw.elapsedMilliseconds} ms');
    });

    test('reads a vowelled book page as written, streaming text', () async {
      final page = _fixture('book.jpg', mp: NuqtaInputPolicy.fastMegapixels);
      final job = engine.read(
        pixels: Uint8List.fromList(page.rgba),
        width: page.w,
        height: page.h,
        prompt: NuqtaMode.asWritten.prompt,
        maxNewTokens: 160,
      );
      final stages = <NuqtaStage>[];
      var pieces = 0;
      job.events.listen((e) {
        if (e is NuqtaStageEvent) stages.add(e.stage);
        if (e is NuqtaTextEvent) pieces++;
      });
      final r = await job.result;
      // ignore: avoid_print
      print(
        'book: ${r.stats.strips} strips, first ${r.stats.firstTokenSeconds}s, '
        '${r.stats.tokensPerSecond.toStringAsFixed(1)} tok/s\n${r.text}',
      );
      expect(r.status, NuqtaStatus.finished);
      expect(
        stages,
        containsAllInOrder([NuqtaStage.reading, NuqtaStage.writing]),
      );
      expect(pieces, greaterThan(5));
      expect(_hasArabic(r.text), isTrue);
      expect(r.stats.outTokens, greaterThan(0));
    });

    test('markdown mode writes a table as HTML', () async {
      final page = _fixture('table.jpg', mp: NuqtaInputPolicy.fastMegapixels);
      final job = engine.read(
        pixels: Uint8List.fromList(page.rgba),
        width: page.w,
        height: page.h,
        prompt: NuqtaMode.markdown.prompt,
        maxNewTokens: 1200,
      );
      final r = await job.result;
      // ignore: avoid_print
      print('table:\n${r.text}');
      expect(r.text.toLowerCase(), contains('<table'));
      expect(_hasArabic(r.text), isTrue);
    });

    test('cancel stops a read early', () async {
      final page = _fixture('book.jpg', mp: NuqtaInputPolicy.fastMegapixels);
      final job = engine.read(
        pixels: Uint8List.fromList(page.rgba),
        width: page.w,
        height: page.h,
        prompt: NuqtaMode.asWritten.prompt,
      );
      var pieces = 0;
      job.events.listen((e) {
        if (e is NuqtaTextEvent && ++pieces == 3) job.cancel();
      });
      final r = await job.result;
      expect(r.status, NuqtaStatus.cancelled);
      expect(pieces, lessThan(10));
    });
  });
}
