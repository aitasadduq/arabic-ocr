/// On-device Nuqta-OCR: llama.cpp + the upstream Nuqta engine, through dart:ffi.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'src/bindings.dart';

export 'src/input_policy.dart';
export 'src/modes.dart';
export 'src/text_cleanup.dart';

enum NuqtaStage { reading, writing }

enum NuqtaStatus { finished, cancelled }

sealed class NuqtaEvent {
  const NuqtaEvent();
}

final class NuqtaStageEvent extends NuqtaEvent {
  const NuqtaStageEvent(this.stage);
  final NuqtaStage stage;
}

final class NuqtaTextEvent extends NuqtaEvent {
  const NuqtaTextEvent(this.piece);
  final String piece;
}

class NuqtaStats {
  const NuqtaStats({
    this.imageTokens = 0,
    this.outTokens = 0,
    this.encodeSeconds = 0,
    this.generateSeconds = 0,
    this.firstTokenSeconds = 0,
    this.strips = 1,
  });

  factory NuqtaStats.fromJson(Map<String, dynamic> j) => NuqtaStats(
    imageTokens: (j['image_tokens'] as num?)?.toInt() ?? 0,
    outTokens: (j['out_tokens'] as num?)?.toInt() ?? 0,
    encodeSeconds: (j['encode_s'] as num?)?.toDouble() ?? 0,
    generateSeconds: (j['gen_s'] as num?)?.toDouble() ?? 0,
    firstTokenSeconds: (j['first_s'] as num?)?.toDouble() ?? 0,
    strips: (j['strips'] as num?)?.toInt() ?? 1,
  );

  final int imageTokens;
  final int outTokens;
  final double encodeSeconds;
  final double generateSeconds;
  final double firstTokenSeconds;
  final int strips;

  double get tokensPerSecond =>
      generateSeconds > 0 ? outTokens / generateSeconds : 0;
}

class NuqtaResult {
  const NuqtaResult(this.text, this.status, this.stats);
  final String text;
  final NuqtaStatus status;
  final NuqtaStats stats;
}

class NuqtaException implements Exception {
  const NuqtaException(this.message);
  final String message;
  @override
  String toString() => 'NuqtaException: $message';
}

/// One read in progress. Text arrives as [events]; [result] completes when the
/// engine stops (finished, cancelled, or an error).
class NuqtaReadJob {
  NuqtaReadJob._(this.id, this._engine);

  final int id;
  final NuqtaEngine _engine;
  final _events = StreamController<NuqtaEvent>.broadcast();
  final _result = Completer<NuqtaResult>();
  final _text = StringBuffer();
  NuqtaStage _stage = NuqtaStage.reading;

  Stream<NuqtaEvent> get events => _events.stream;
  Future<NuqtaResult> get result => _result.future;
  String get text => _text.toString();
  NuqtaStage get stage => _stage;
  bool get isDone => _result.isCompleted;

  void cancel() {
    if (!isDone) _engine._b.cancel(id);
  }

  void _onStage(int value) {
    _stage = value == 0 ? NuqtaStage.reading : NuqtaStage.writing;
    _events.add(NuqtaStageEvent(_stage));
  }

  void _onText(String piece) {
    _text.write(piece);
    _events.add(NuqtaTextEvent(piece));
  }

  void _onDone(int value, String? payload) {
    if (value == 0) {
      _result.completeError(NuqtaException(payload ?? 'read failed'));
    } else {
      NuqtaStats stats = const NuqtaStats();
      if (payload != null) {
        try {
          stats = NuqtaStats.fromJson(
            jsonDecode(payload) as Map<String, dynamic>,
          );
        } on FormatException {
          // stats are informational only
        }
      }
      _result.complete(
        NuqtaResult(
          text,
          value == 2 ? NuqtaStatus.cancelled : NuqtaStatus.finished,
          stats,
        ),
      );
    }
    _events.close();
  }
}

/// The process-wide engine. One model is loaded at a time and reads run one
/// after another on a native thread.
class NuqtaEngine {
  NuqtaEngine._(this._b) {
    _callable = NativeCallable<NuqtaEventNative>.listener(_onEvent)
      ..keepIsolateAlive = false;
    _b.setEventCallback(_callable.nativeFunction);
  }

  /// Opens the engine library. [libraryPath] is for host tests; apps leave it
  /// null.
  factory NuqtaEngine({String? libraryPath}) => _instance ??= NuqtaEngine._(
    NuqtaBindings(NuqtaBindings.open(libraryPath)),
  );

  static NuqtaEngine? _instance;

  final NuqtaBindings _b;
  late final NativeCallable<NuqtaEventNative> _callable;
  int _nextJob = 1;
  final _loads = <int, Completer<void>>{};
  final _reads = <int, NuqtaReadJob>{};

  bool get isLoaded => _b.isLoaded() != 0;

  String get version => _b.version().cast<Utf8>().toDartString();

  int get defaultThreads => _b.defaultThreads();

  /// Loads the model (GGUF) and its vision projector (mmproj GGUF).
  Future<void> load({
    required String modelPath,
    required String mmprojPath,
    int threads = 0,
    int imageMaxTokens = 4096,
    String backendDir = '',
  }) {
    final job = _nextJob++;
    final done = Completer<void>();
    _loads[job] = done;
    _keepAlive();
    using((arena) {
      _b.loadAsync(
        job,
        modelPath.toNativeUtf8(allocator: arena).cast(),
        mmprojPath.toNativeUtf8(allocator: arena).cast(),
        threads,
        imageMaxTokens,
        backendDir.toNativeUtf8(allocator: arena).cast(),
      );
    });
    return done.future;
  }

  /// Starts reading an image. [pixels] holds width*height*[channels] bytes
  /// (3 = RGB, 4 = RGBA). The pixels are copied before this returns.
  NuqtaReadJob read({
    required Uint8List pixels,
    required int width,
    required int height,
    int channels = 4,
    required String prompt,
    int maxNewTokens = 4096,
    bool strips = true,
  }) {
    if (pixels.length < width * height * channels) {
      throw ArgumentError.value(pixels.length, 'pixels', 'too short');
    }
    final job = NuqtaReadJob._(_nextJob++, this);
    _reads[job.id] = job;
    _keepAlive();
    using((arena) {
      final buf = arena<Uint8>(pixels.length);
      buf.asTypedList(pixels.length).setAll(0, pixels);
      _b.readAsync(
        job.id,
        buf,
        width,
        height,
        channels,
        prompt.toNativeUtf8(allocator: arena).cast(),
        maxNewTokens,
        strips ? 1 : 0,
      );
    });
    return job;
  }

  /// Frees the model. Call only when no read is running.
  void unload() => _b.unload();

  void _keepAlive() {
    _callable.keepIsolateAlive = _loads.isNotEmpty || _reads.isNotEmpty;
  }

  void _onEvent(int job, int kind, int value, Pointer<Char> text, int len) {
    String? payload;
    if (text != nullptr) {
      payload = utf8.decode(
        text.cast<Uint8>().asTypedList(len),
        allowMalformed: true,
      );
      _b.free(text.cast());
    }
    switch (kind) {
      case NuqtaEventKind.loaded:
        final c = _loads.remove(job);
        if (value == 1) {
          c?.complete();
        } else {
          c?.completeError(
            NuqtaException(payload ?? 'could not load the model'),
          );
        }
      case NuqtaEventKind.stage:
        _reads[job]?._onStage(value);
      case NuqtaEventKind.text:
        if (payload != null) _reads[job]?._onText(payload);
      case NuqtaEventKind.done:
        _reads.remove(job)?._onDone(value, payload);
    }
    _keepAlive();
  }
}
