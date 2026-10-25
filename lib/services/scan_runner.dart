import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nuqta_engine/nuqta_engine.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/scan.dart';
import 'history_store.dart';
import 'ocr_backend.dart';
import 'page_loader.dart';

/// Reads the pages of a scan one after another, streaming the text into each
/// [ScanPage] as it is written.
class ScanRunner extends ChangeNotifier {
  ScanRunner({
    required this.backend,
    required this.loader,
    required this.history,
    required this.keepHistory,
    bool? pauseInBackground,
    this.useWakelock = true,
  }) : pauseInBackground = pauseInBackground ?? (!kIsWeb && Platform.isIOS) {
    _lifecycle = AppLifecycleListener(onHide: _onHide, onShow: _onShow);
  }

  final OcrBackend backend;
  final PageLoader loader;
  final HistoryStore history;
  final bool Function() keepHistory;

  /// iOS stops GPU work in the background, so the current page is stopped
  /// there and read again when the app comes back.
  final bool pauseInBackground;
  final bool useWakelock;

  late final AppLifecycleListener _lifecycle;

  Scan? _scan;
  ScanPage? _page;
  OcrJob? _job;
  bool _stopRequested = false;
  bool _hidden = false;
  bool _interruptedByBackground = false;
  Completer<void>? _running;
  DateTime? _pageStarted;

  Scan? get scan => _scan;
  ScanPage? get currentPage => _page;
  bool get isRunning => _running != null && !_running!.isCompleted;
  bool get isPausedInBackground => _interruptedByBackground;
  DateTime? get pageStartedAt => _pageStarted;

  /// Starts (or continues) reading every queued page of [scan].
  Future<void> run(Scan scan) async {
    if (isRunning) {
      if (identical(scan, _scan)) return _running!.future;
      await stop();
    }
    _scan = scan;
    _stopRequested = false;
    final running = _running = Completer<void>();
    notifyListeners();
    if (useWakelock) unawaited(WakelockPlus.enable().catchError((_) {}));
    try {
      while (!_stopRequested) {
        final next = scan.pages
            .where((p) => p.status == PageStatus.queued)
            .firstOrNull;
        if (next == null) break;
        if (_hidden && pauseInBackground) {
          _interruptedByBackground = true;
          notifyListeners();
          break;
        }
        await _readPage(scan, next);
        if (keepHistory()) await history.save(scan);
      }
    } finally {
      _page = null;
      _job = null;
      _pageStarted = null;
      if (useWakelock) unawaited(WakelockPlus.disable().catchError((_) {}));
      // PDFs stay open while their pages are read; let them go now
      unawaited(loader.closeAll().catchError((_) {}));
      running.complete();
      notifyListeners();
    }
  }

  /// Puts a finished page back in the queue and reads it again.
  Future<void> retry(Scan scan, ScanPage page) {
    page
      ..status = PageStatus.queued
      ..text = ''
      ..error = null;
    notifyListeners();
    return run(scan);
  }

  /// Stops the current page and leaves the rest queued.
  Future<void> stop() async {
    _stopRequested = true;
    _job?.cancel();
    await _running?.future;
  }

  /// Stops and marks every unread page as cancelled.
  Future<void> cancelAll() async {
    final scan = _scan;
    await stop();
    if (scan == null) return;
    for (final p in scan.pages) {
      if (p.status == PageStatus.queued) p.status = PageStatus.cancelled;
    }
    notifyListeners();
    if (keepHistory()) await history.save(scan);
  }

  Future<void> _readPage(Scan scan, ScanPage page) async {
    _page = page;
    _pageStarted = DateTime.now();
    page
      ..status = PageStatus.preparing
      ..text = ''
      ..error = null;
    notifyListeners();

    PreparedImage image;
    try {
      // read again from the stored page image when the original is gone
      final source = page.imagePath != null && _sourceMissing(page.source)
          ? FilePageSource(page.imagePath!)
          : page.source;
      final turns = identical(source, page.source) ? page.quarterTurns : 0;
      image = await loader.load(
        source,
        megapixels: scan.quality.megapixels,
        quarterTurns: turns,
      );
    } catch (e) {
      page
        ..status = PageStatus.failed
        ..error = e is PageLoadException ? e.kind.name : '$e';
      notifyListeners();
      return;
    }

    if (page.imagePath == null && keepHistory()) {
      unawaited(_storeImage(scan, page, image));
    }

    page.status = PageStatus.reading;
    notifyListeners();
    final job = _job = backend.read(image, scan.mode);
    var lastNotify = DateTime.now();
    final sub = job.events.listen((e) {
      switch (e) {
        case NuqtaStageEvent(:final stage):
          page.status = stage == NuqtaStage.writing
              ? PageStatus.writing
              : PageStatus.reading;
          notifyListeners();
        case NuqtaTextEvent(:final piece):
          page.text += piece;
          final now = DateTime.now();
          if (now.difference(lastNotify).inMilliseconds >= 50) {
            lastNotify = now;
            notifyListeners();
          }
      }
    });
    try {
      final r = await job.result;
      page
        ..text = NuqtaText.finish(r.text)
        ..tokens = r.stats.outTokens
        ..firstWordsSeconds = r.stats.firstTokenSeconds
        ..seconds =
            DateTime.now().difference(_pageStarted!).inMilliseconds / 1000;
      if (r.status == NuqtaStatus.cancelled) {
        // stopped for the background: read the page again later
        page.status = _interruptedByBackground
            ? PageStatus.queued
            : PageStatus.cancelled;
        if (page.status == PageStatus.queued) page.text = '';
      } else {
        page.status = PageStatus.done;
      }
    } catch (e) {
      page
        ..status = PageStatus.failed
        ..error = e is NuqtaException ? e.message : '$e';
    } finally {
      await sub.cancel();
      _job = null;
      notifyListeners();
    }
  }

  bool _sourceMissing(PageSource s) => switch (s) {
    FilePageSource(:final path) => !File(path).existsSync(),
    PdfPageSource(:final path) => !File(path).existsSync(),
    AssetPageSource() => false,
  };

  Future<void> _storeImage(
    Scan scan,
    ScanPage page,
    PreparedImage image,
  ) async {
    try {
      final jpeg = await PageLoader.encodePreview(image);
      page.imagePath = await history.savePageImage(scan, page, jpeg);
      notifyListeners();
    } catch (_) {
      // the image is a convenience; reading goes on without it
    }
  }

  void _onHide() {
    _hidden = true;
    if (pauseInBackground && isRunning) {
      _interruptedByBackground = true;
      _stopRequested = true;
      _job?.cancel();
      notifyListeners();
    }
  }

  void _onShow() {
    _hidden = false;
    if (_interruptedByBackground) {
      _interruptedByBackground = false;
      final scan = _scan;
      if (scan != null) {
        unawaited(_running?.future.then((_) => run(scan)) ?? run(scan));
      }
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _job?.cancel();
    super.dispose();
  }
}
