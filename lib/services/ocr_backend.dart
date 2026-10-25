import 'dart:async';

import 'package:nuqta_engine/nuqta_engine.dart';

import 'page_loader.dart';

/// One read in progress.
abstract class OcrJob {
  Stream<NuqtaEvent> get events;
  Future<NuqtaResult> get result;
  void cancel();
}

/// The OCR engine as the app sees it. [NuqtaBackend] runs the real model;
/// [DemoBackend] streams canned text (tests, screenshots, simulators).
abstract class OcrBackend {
  bool get isLoaded;
  Future<void> load({required String modelPath, required String mmprojPath});
  OcrJob read(PreparedImage image, NuqtaMode mode);
  void unload();
}

class NuqtaBackend implements OcrBackend {
  NuqtaEngine? _engine;

  NuqtaEngine get engine => _engine ??= NuqtaEngine();

  @override
  bool get isLoaded => _engine?.isLoaded ?? false;

  @override
  Future<void> load({required String modelPath, required String mmprojPath}) =>
      engine.load(modelPath: modelPath, mmprojPath: mmprojPath);

  @override
  OcrJob read(PreparedImage image, NuqtaMode mode) => _NuqtaJob(
    engine.read(
      pixels: image.rgba,
      width: image.width,
      height: image.height,
      channels: 4,
      prompt: mode.prompt,
    ),
  );

  @override
  void unload() => _engine?.unload();
}

class _NuqtaJob implements OcrJob {
  _NuqtaJob(this._job);
  final NuqtaReadJob _job;

  @override
  Stream<NuqtaEvent> get events => _job.events;
  @override
  Future<NuqtaResult> get result => _job.result;
  @override
  void cancel() => _job.cancel();
}

/// Streams fixed text at a steady pace, like the real model does.
class DemoBackend implements OcrBackend {
  DemoBackend({
    this.loadDelay = const Duration(milliseconds: 300),
    this.readDelay = const Duration(milliseconds: 400),
    this.pieceDelay = const Duration(milliseconds: 25),
    Map<NuqtaMode, String>? texts,
  }) : texts = texts ?? demoTexts;

  final Duration loadDelay;
  final Duration readDelay;
  final Duration pieceDelay;
  final Map<NuqtaMode, String> texts;
  bool _loaded = false;

  static const demoTexts = {
    NuqtaMode.asWritten:
        'يَتَدَحْرَجُ بِسُرْعَةٍ كَبِيرَةٍ أَشْعَرَتْهُ بِالدُّوَارِ.\n'
        'فِي الْبِدَايَةِ، كَانَ رَأْسُهُ بِالْأَعْلَى، ثُمَّ انْقَلَبَ لِيَصِيرَ بِالْأَسْفَلِ.\n'
        'وَكُلُّ ذَلِكَ كَانَ يَحْدُثُ بِسُرْعَةٍ بَالِغَةٍ.',
    NuqtaMode.bare:
        'يتدحرج بسرعة كبيرة أشعرته بالدوار.\n'
        'في البداية، كان رأسه بالأعلى، ثم انقلب ليصير بالأسفل.',
    NuqtaMode.markdown:
        '# جدول رقم ( ١٢٣ )\n'
        'يوضح رؤية أفراد العينة الأولى حول فاعلية كفالة الدعاة لتحقيق الهدف الثاني\n'
        '<table>\n<thead>\n<tr><th>الرأي</th><th>العدد</th><th>النسبة المئوية</th><th>المتوسط الحسابي</th></tr>\n</thead>\n'
        '<tbody>\n<tr><td>غير فعالة على الإطلاق</td><td>١</td><td>٣%</td><td rowspan="5">٤,٥٩</td></tr>\n'
        '<tr><td>غير فعالة</td><td>١</td><td>٣%</td></tr>\n'
        '<tr><td>فعالة إلى حد ما</td><td>١٩</td><td>٦,٣</td></tr>\n'
        '<tr><td>فعالة</td><td>٧٥</td><td>٢٥,٠</td></tr>\n'
        '<tr><td>فعالة جداً</td><td>١٩٩</td><td>٦٦,٣</td></tr>\n'
        '</tbody>\n</table>\n'
        '**النتيجة:** بلغ المتوسط الحسابي ٤,٥٩ من ٥.\n'
        '- فعالة جداً: ٦٦,٣%\n- فعالة: ٢٥,٠%',
  };

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> load({
    required String modelPath,
    required String mmprojPath,
  }) async {
    await Future<void>.delayed(loadDelay);
    _loaded = true;
  }

  @override
  OcrJob read(PreparedImage image, NuqtaMode mode) =>
      _DemoJob(texts[mode] ?? '', readDelay, pieceDelay);

  @override
  void unload() => _loaded = false;
}

class _DemoJob implements OcrJob {
  _DemoJob(String text, Duration readDelay, Duration pieceDelay) {
    _run(text, readDelay, pieceDelay);
  }

  final _events = StreamController<NuqtaEvent>.broadcast();
  final _result = Completer<NuqtaResult>();
  bool _cancelled = false;

  Future<void> _run(
    String text,
    Duration readDelay,
    Duration pieceDelay,
  ) async {
    final sw = Stopwatch()..start();
    _events.add(const NuqtaStageEvent(NuqtaStage.reading));
    await Future<void>.delayed(readDelay);
    _events.add(const NuqtaStageEvent(NuqtaStage.writing));
    final first = sw.elapsedMilliseconds / 1000;
    final out = StringBuffer();
    final words = RegExp(r'\S+\s*|\s+').allMatches(text).map((m) => m[0]!);
    var n = 0;
    for (final w in words) {
      if (_cancelled) break;
      out.write(w);
      n++;
      _events.add(NuqtaTextEvent(w));
      await Future<void>.delayed(pieceDelay);
    }
    final gen = sw.elapsedMilliseconds / 1000 - first;
    _result.complete(
      NuqtaResult(
        out.toString(),
        _cancelled ? NuqtaStatus.cancelled : NuqtaStatus.finished,
        NuqtaStats(
          outTokens: n,
          firstTokenSeconds: first,
          generateSeconds: gen,
          encodeSeconds: first,
        ),
      ),
    );
    await _events.close();
  }

  @override
  Stream<NuqtaEvent> get events => _events.stream;
  @override
  Future<NuqtaResult> get result => _result.future;
  @override
  void cancel() => _cancelled = true;
}
