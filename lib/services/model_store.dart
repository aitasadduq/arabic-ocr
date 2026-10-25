import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'ocr_backend.dart';
import 'platform_channel.dart';

/// One of the two GGUF files the model needs.
class ModelFileSpec {
  const ModelFileSpec(this.name, this.size, {this.legacySize});

  final String name;
  final int size;

  /// The size of the file before an upstream re-upload (same weights).
  final int? legacySize;

  static const _tolerance = 65536;
  static const baseUrl =
      'https://huggingface.co/SalahALHaismawi/Nuqta-OCR-0.8B-GGUF/resolve/main';

  String get url => '$baseUrl/$name';

  bool acceptsSize(int length) =>
      (length - size).abs() <= _tolerance ||
      (legacySize != null && (length - legacySize!).abs() <= _tolerance);
}

enum ModelStatus {
  /// Not checked yet.
  unknown,
  missing,
  downloading,
  paused,

  /// Files are present; the engine is loading them.
  loading,
  ready,
  error,
}

enum ModelError { download, verify, load, import, storage }

/// Downloads files in the background. Abstract so tests can fake it.
abstract class ModelDownloader {
  /// Downloads [file] into [dir], reporting progress in 0..1. Completes when the
  /// file is there; throws on failure or cancel.
  Future<void> download(
    ModelFileSpec file,
    Directory dir, {
    required bool wifiOnly,
    required void Function(double progress) onProgress,
    required void Function(bool paused) onPaused,
  });

  Future<void> pause();
  Future<void> resume();
  Future<void> cancel();
}

/// Owns the model files and the engine's loaded state.
class ModelStore extends ChangeNotifier {
  ModelStore({
    required this.backend,
    ModelDownloader? downloader,
    Future<Directory> Function()? baseDir,
    PlatformChannel? platform,
  }) : _downloader = downloader ?? BackgroundModelDownloader(),
       _baseDir = baseDir ?? getApplicationSupportDirectory,
       _platform = platform ?? PlatformChannel();

  static const model = ModelFileSpec(
    'nuqta-ocr-0.8b-Q4_K_M.gguf',
    559595520,
    legacySize: 559595392,
  );
  static const mmproj = ModelFileSpec(
    'nuqta-ocr-0.8b-mmproj-f16.gguf',
    204986688,
    legacySize: 204986656,
  );
  static const files = [model, mmproj];
  static int get totalBytes => model.size + mmproj.size;

  final OcrBackend backend;
  final ModelDownloader _downloader;
  final Future<Directory> Function() _baseDir;
  final PlatformChannel _platform;

  ModelStatus _status = ModelStatus.unknown;
  ModelStatus get status => _status;
  ModelError? error;
  String? errorDetail;

  /// Overall download progress, 0..1.
  double progress = 0;
  bool get isReady => _status == ModelStatus.ready;
  bool get isBusy =>
      _status == ModelStatus.downloading ||
      _status == ModelStatus.paused ||
      _status == ModelStatus.loading;

  Directory? _dir;

  Future<Directory> modelDir() async {
    return _dir ??= Directory(p.join((await _baseDir()).path, 'models'));
  }

  Future<String> pathOf(ModelFileSpec f) async =>
      p.join((await modelDir()).path, f.name);

  void _set(ModelStatus s, {ModelError? err, String? detail}) {
    _status = s;
    error = err;
    errorDetail = detail;
    notifyListeners();
  }

  Future<bool> _present(ModelFileSpec f) async {
    final file = File(await pathOf(f));
    return await file.exists() && f.acceptsSize(await file.length());
  }

  /// Checks the files and loads the engine when they are there.
  Future<void> init() async {
    if (isBusy) return;
    final all = await Future.wait(files.map(_present));
    if (all.every((x) => x)) {
      await loadEngine();
    } else {
      _set(ModelStatus.missing);
    }
  }

  Future<void> loadEngine() async {
    if (backend.isLoaded) {
      _set(ModelStatus.ready);
      return;
    }
    _set(ModelStatus.loading);
    try {
      await backend.load(
        modelPath: await pathOf(model),
        mmprojPath: await pathOf(mmproj),
      );
      _set(ModelStatus.ready);
    } catch (e) {
      _set(ModelStatus.error, err: ModelError.load, detail: '$e');
    }
  }

  /// Downloads whatever is missing (resuming partial downloads), then loads.
  Future<void> download({bool wifiOnly = false}) async {
    if (_status == ModelStatus.downloading) return;
    final dir = await modelDir();
    try {
      await dir.create(recursive: true);
    } catch (e) {
      _set(ModelStatus.error, err: ModelError.storage, detail: '$e');
      return;
    }
    progress = 0;
    _set(ModelStatus.downloading);
    var doneBytes = 0;
    try {
      for (final f in files) {
        if (await _present(f)) {
          doneBytes += f.size;
          continue;
        }
        final before = doneBytes;
        await _downloader.download(
          f,
          dir,
          wifiOnly: wifiOnly,
          onProgress: (x) {
            progress = (before + x.clamp(0.0, 1.0) * f.size) / totalBytes;
            notifyListeners();
          },
          onPaused: (paused) =>
              _set(paused ? ModelStatus.paused : ModelStatus.downloading),
        );
        if (!await _present(f)) {
          _set(ModelStatus.error, err: ModelError.verify, detail: f.name);
          return;
        }
        doneBytes += f.size;
      }
    } catch (e) {
      if (_status != ModelStatus.missing) {
        _set(ModelStatus.error, err: ModelError.download, detail: '$e');
      }
      return;
    }
    progress = 1;
    await _platform.excludeFromBackup(dir.path);
    await loadEngine();
  }

  Future<void> pause() => _downloader.pause();
  Future<void> resume() => _downloader.resume();

  Future<void> cancelDownload() async {
    _set(ModelStatus.missing);
    await _downloader.cancel();
  }

  /// Copies model files the user picked (e.g. from Files) into place. Returns
  /// the names that were not recognised.
  Future<List<String>> importFiles(List<String> paths) async {
    final dir = await modelDir();
    await dir.create(recursive: true);
    final unknown = <String>[];
    for (final path in paths) {
      final src = File(path);
      final len = await src.length();
      final spec = files.where((f) => f.acceptsSize(len)).firstOrNull;
      if (spec == null || !await _isGguf(src)) {
        unknown.add(p.basename(path));
        continue;
      }
      final dest = await pathOf(spec);
      final tmp = '$dest.import';
      await src.copy(tmp);
      await File(tmp).rename(dest);
    }
    await _platform.excludeFromBackup(dir.path);
    await init();
    return unknown;
  }

  static Future<bool> _isGguf(File f) async {
    final raf = await f.open();
    try {
      final magic = await raf.read(4);
      return magic.length == 4 && String.fromCharCodes(magic) == 'GGUF';
    } finally {
      await raf.close();
    }
  }

  /// Removes the model files (frees ~765 MB).
  Future<void> delete() async {
    backend.unload();
    final dir = await modelDir();
    if (await dir.exists()) await dir.delete(recursive: true);
    progress = 0;
    _set(ModelStatus.missing);
  }

  /// Bytes the model files take on disk.
  Future<int> bytesOnDisk() async {
    var n = 0;
    for (final f in files) {
      final file = File(await pathOf(f));
      if (await file.exists()) n += await file.length();
    }
    return n;
  }
}

/// [ModelDownloader] on background_downloader: the download keeps going when
/// the app is in the background (URLSession on iOS, WorkManager/UIDT on
/// Android) and resumes after interruptions.
class BackgroundModelDownloader implements ModelDownloader {
  Transfer? _current;
  bool _started = false;

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    await FileDownloader().start(autoCleanDatabase: true);
  }

  @override
  Future<void> download(
    ModelFileSpec file,
    Directory dir, {
    required bool wifiOnly,
    required void Function(double progress) onProgress,
    required void Function(bool paused) onPaused,
  }) async {
    await _start();
    final task = DownloadTask(
      taskId: 'model-${file.name}',
      url: file.url,
      filename: file.name,
      directory: 'models',
      baseDirectory: BaseDirectory.applicationSupport,
      requiresWiFi: wifiOnly,
      retries: 5,
      updates: Updates.statusAndProgress,
      displayName: 'Arabic OCR model',
      transferHints: {TransferHint.userInitiated, TransferHint.largeFile},
      notificationConfig: TaskNotificationConfig(
        running: TaskNotification('Downloading the OCR model', '{progress}'),
        complete: TaskNotification(
          'OCR model downloaded',
          'Ready to read pages offline',
        ),
        error: TaskNotification(
          'Model download failed',
          'Open the app to try again',
        ),
        paused: TaskNotification('Model download paused', '{progress}'),
        progressBar: true,
      ),
    );
    final transfer = await FileDownloader().transfers.getOrStart(task);
    _current = transfer;
    void progress() {
      final v = transfer.progressNotifier.value;
      if (v != null && v >= 0) onProgress(v);
    }

    void status() =>
        onPaused(transfer.statusNotifier.value == TaskStatus.paused);
    transfer.progressNotifier.addListener(progress);
    transfer.statusNotifier.addListener(status);
    try {
      final result = await transfer.result;
      if (result.status != TaskStatus.complete) {
        throw Exception(result.exception?.description ?? result.status.name);
      }
      // background_downloader writes to the app support folder; make sure the
      // file ended up where the store looks for it
      final expected = File(p.join(dir.path, file.name));
      if (!await expected.exists()) {
        final written = File(await task.filePath());
        if (await written.exists()) await written.rename(expected.path);
      }
    } finally {
      transfer.progressNotifier.removeListener(progress);
      transfer.statusNotifier.removeListener(status);
      _current = null;
    }
  }

  @override
  Future<void> pause() async => _current?.pause();

  @override
  Future<void> resume() async => _current?.resume();

  @override
  Future<void> cancel() async => _current?.cancel();
}
