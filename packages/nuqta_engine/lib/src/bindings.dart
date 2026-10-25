// Hand-written bindings for src/nuqta_ffi.h (the API is small enough that
// generated bindings would add more than they save).
import 'dart:ffi';
import 'dart:io';

typedef NuqtaEventNative =
    Void Function(
      Int32 job,
      Int32 kind,
      Int32 value,
      Pointer<Char> text,
      Int32 textLen,
    );
typedef NuqtaEventDart =
    void Function(
      int job,
      int kind,
      int value,
      Pointer<Char> text,
      int textLen,
    );

abstract final class NuqtaEventKind {
  static const loaded = 0;
  static const stage = 1;
  static const text = 2;
  static const done = 3;
}

final class NuqtaBindings {
  NuqtaBindings(DynamicLibrary lib)
    : setEventCallback = lib
          .lookupFunction<
            Void Function(Pointer<NativeFunction<NuqtaEventNative>>),
            void Function(Pointer<NativeFunction<NuqtaEventNative>>)
          >('nuqta_set_event_callback'),
      loadAsync = lib
          .lookupFunction<
            Void Function(
              Int32,
              Pointer<Char>,
              Pointer<Char>,
              Int32,
              Int32,
              Pointer<Char>,
            ),
            void Function(
              int,
              Pointer<Char>,
              Pointer<Char>,
              int,
              int,
              Pointer<Char>,
            )
          >('nuqta_load_async'),
      readAsync = lib
          .lookupFunction<
            Void Function(
              Int32,
              Pointer<Uint8>,
              Int32,
              Int32,
              Int32,
              Pointer<Char>,
              Int32,
              Int32,
            ),
            void Function(
              int,
              Pointer<Uint8>,
              int,
              int,
              int,
              Pointer<Char>,
              int,
              int,
            )
          >('nuqta_read_async'),
      cancel = lib.lookupFunction<Void Function(Int32), void Function(int)>(
        'nuqta_cancel',
      ),
      isLoaded = lib.lookupFunction<Int32 Function(), int Function()>(
        'nuqta_is_loaded',
      ),
      unload = lib.lookupFunction<Void Function(), void Function()>(
        'nuqta_unload',
      ),
      free = lib
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('nuqta_free'),
      defaultThreads = lib.lookupFunction<Int32 Function(), int Function()>(
        'nuqta_default_threads',
      ),
      libraryDir = lib
          .lookupFunction<Pointer<Char> Function(), Pointer<Char> Function()>(
            'nuqta_library_dir',
          ),
      version = lib
          .lookupFunction<Pointer<Char> Function(), Pointer<Char> Function()>(
            'nuqta_version',
          );

  final void Function(Pointer<NativeFunction<NuqtaEventNative>>)
  setEventCallback;
  final void Function(
    int job,
    Pointer<Char> model,
    Pointer<Char> mmproj,
    int threads,
    int imageMaxTokens,
    Pointer<Char> backendDir,
  )
  loadAsync;
  final void Function(
    int job,
    Pointer<Uint8> pixels,
    int w,
    int h,
    int channels,
    Pointer<Char> prompt,
    int maxNewTokens,
    int strips,
  )
  readAsync;
  final void Function(int job) cancel;
  final int Function() isLoaded;
  final void Function() unload;
  final void Function(Pointer<Void>) free;
  final int Function() defaultThreads;
  final Pointer<Char> Function() libraryDir;
  final Pointer<Char> Function() version;

  /// Opens the engine library for the current platform. [path] overrides the
  /// default location (host tests point it at a CMake build).
  static DynamicLibrary open([String? path]) {
    path ??= Platform.environment['NUQTA_ENGINE_LIB'];
    if (path != null && path.isNotEmpty) return DynamicLibrary.open(path);
    if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('libnuqta_engine.so');
    }
    if (Platform.isIOS || Platform.isMacOS) {
      try {
        return DynamicLibrary.open('nuqta_engine.framework/nuqta_engine');
      } on ArgumentError {
        return DynamicLibrary.process();
      }
    }
    throw UnsupportedError('Nuqta engine is not available on this platform');
  }
}
