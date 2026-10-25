import 'dart:io';

import 'package:arabic_ocr/app_scope.dart';
import 'package:arabic_ocr/models/scan.dart';
import 'package:arabic_ocr/services/history_store.dart';
import 'package:arabic_ocr/services/model_store.dart';
import 'package:arabic_ocr/services/ocr_backend.dart';
import 'package:arabic_ocr/services/page_loader.dart';
import 'package:arabic_ocr/services/scan_runner.dart';
import 'package:arabic_ocr/services/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Writes model files of the right size (sparse, so nearly free).
Future<void> fakeModelFiles(Directory base) async {
  final dir = Directory('${base.path}/models')..createSync(recursive: true);
  for (final f in ModelStore.files) {
    final raf = await File('${dir.path}/${f.name}').open(mode: FileMode.write);
    await raf.writeFrom('GGUF'.codeUnits);
    await raf.truncate(f.size);
    await raf.close();
  }
}

class NoDownloader implements ModelDownloader {
  @override
  Future<void> download(
    ModelFileSpec file,
    Directory dir, {
    required bool wifiOnly,
    required void Function(double progress) onProgress,
    required void Function(bool paused) onPaused,
  }) async => throw UnsupportedError('no network in tests');

  @override
  Future<void> cancel() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
}

/// Returns a small white page at once (no image decoding).
class InstantLoader extends PageLoader {
  @override
  Future<PreparedImage> load(
    PageSource source, {
    required double megapixels,
    int quarterTurns = 0,
  }) => SynchronousFuture(
    PreparedImage(Uint8List(8 * 8 * 4)..fillRange(0, 256, 255), 8, 8),
  );
}

/// Services with the demo engine, in-memory settings and files under [dir].
Future<AppServices> fakeServices(
  Directory dir, {
  bool modelReady = true,
  OcrBackend? backend,
  PageLoader? pageLoader,
  bool keepHistory = true,
}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  if (modelReady) await fakeModelFiles(dir);
  final settings = await Settings.load();
  final engine =
      backend ??
      DemoBackend(
        loadDelay: Duration.zero,
        readDelay: const Duration(milliseconds: 50),
        pieceDelay: const Duration(milliseconds: 5),
      );
  final history = HistoryStore(baseDir: () async => dir);
  final loader = pageLoader ?? InstantLoader();
  if (!keepHistory) settings.keepHistory = false;
  return AppServices(
    settings: settings,
    backend: engine,
    models: ModelStore(
      backend: engine,
      downloader: NoDownloader(),
      baseDir: () async => dir,
    ),
    history: history,
    loader: loader,
    runner: ScanRunner(
      backend: engine,
      loader: loader,
      history: history,
      keepHistory: () => settings.keepHistory,
      pauseInBackground: false,
      useWakelock: false,
    ),
  );
}

/// Loads the app's fonts and Material icons so screenshots show real text.
Future<void> loadAppFonts() async {
  Future<void> family(String name, List<String> assets) async {
    final loader = FontLoader(name);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  await family('IBMPlexSans', ['assets/fonts/IBMPlexSans.ttf']);
  await family('NotoSansArabic', ['assets/fonts/NotoSansArabic.ttf']);
  await family('NotoNaskhArabic', ['assets/fonts/NotoNaskhArabic.ttf']);
  await family('SourceSerif4', ['assets/fonts/SourceSerif4.ttf']);
  // the Material icon font ships with the Flutter SDK
  final sdk =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent
          .path;
  final icons = File(
    '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}
