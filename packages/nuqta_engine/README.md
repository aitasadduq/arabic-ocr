# nuqta_engine

On-device [Nuqta-OCR](https://github.com/SalahAlHaismawi/nuqta-ocr) for Flutter.
It runs the upstream C++ engine (`src/upstream`, unchanged) on llama.cpp and
calls it through `dart:ffi`.

* **Android:** CPU. The CPU backend is built for every ARM feature level, and the best one is loaded at run time. This is the same set-up as the upstream Android app.
* **iOS:** GPU (Metal), through a prebuilt `llama.xcframework`.

## Building

| Target | What to do |
|---|---|
| Android | Nothing. Gradle runs `src/CMakeLists.txt`, which fetches llama.cpp at the pinned commit if `third_party/llama.cpp` is missing. The app must set `packaging.jniLibs.useLegacyPackaging = true`. |
| iOS | Run `tool/build_ios_xcframework.sh` once on a Mac (Xcode + CMake). Then use `flutter build ios` as usual. |
| Host tests | `cmake -S src -B build -G Ninja -DCMAKE_BUILD_TYPE=Release && cmake --build build`, then `NUQTA_ENGINE_LIB=$PWD/build/libnuqta_engine.so flutter test`. Set `NUQTA_MODEL_DIR` to a folder with the two GGUF files to run the real-model tests. |

## API

```dart
final engine = NuqtaEngine();
await engine.load(modelPath: model, mmprojPath: mmproj);
final job = engine.read(pixels: rgba, width: w, height: h, prompt: NuqtaMode.markdown.prompt);
job.events.listen((e) { if (e is NuqtaTextEvent) print(e.piece); });
final result = await job.result; // job.cancel() stops early
```
