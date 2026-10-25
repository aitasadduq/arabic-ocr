# Nuqta OCR for Flutter — plan

Offline Arabic OCR app for Android and iOS, built on the open
[Nuqta-OCR](https://github.com/SalahAlHaismawi/nuqta-ocr) 0.8B model.

## Key facts that shape the design

| Fact | Source | Consequence |
|---|---|---|
| Nuqta-OCR is a generative vision-language model (0.8B and 4B). It is not a detector + recogniser pipeline. | nuqta-ocr README | Inference runs as LLM decoding with an image prompt. On-device means llama.cpp + `mtmd`. |
| The 0.8B ships as GGUF: `nuqta-ocr-0.8b-Q4_K_M.gguf` (~560 MB) + `nuqta-ocr-0.8b-mmproj-f16.gguf` (~205 MB). | upstream `apps/android/.../ModelStore.kt` | ~765 MB is too large to bundle in a store build. The app downloads it once (resumable) or imports it from Files. After that, everything is offline. |
| Upstream already has a tested C++ engine (`apps/core/nuqta_core.cpp`) on llama.cpp commit `5aeac37a`. It handles strip reading, margin trim and the loop guard. | upstream `apps/` | We reuse this engine unchanged (Apache-2.0) behind a C ABI, called from Dart through `dart:ffi`. |
| Upstream runs CPU on Android and Metal GPU on iPhone. | upstream `apps/README.md` | Same backends here. |
| The `markdown` mode outputs headings, paragraphs, lists and **HTML tables**. | nuqta-ocr README | The output is parsed into a document model. Save formats are chosen by content: TXT for plain text; DOCX / HTML / MD for structured output; XLSX / CSV for tables. |
| The 4B GGUF is ~2.9 GB. | nuqta-ocr README | Out of scope for phones in v1 (RAM limits). |

## Architecture

```
lib/                      Flutter app (UI, state, services)
  core/                   document model, parsers, exporters (pure Dart, unit-tested)
  services/               model download, image + PDF pipeline, OCR queue, history
  ui/                     screens and widgets, adaptive layouts
packages/nuqta_engine/    FFI plugin
  src/nuqta_core.*        upstream engine (vendored, Apache-2.0)
  src/nuqta_ffi.*         C ABI: async load/read on a native thread, callbacks via NativeCallable.listener, cancel flag
  android/ + src/CMakeLists.txt  NDK build of llama.cpp + mtmd + engine (arm64-v8a, x86_64 for emulators)
  ios/                    podspec linking llama.xcframework (Metal) + engine sources
  tool/fetch_llama.sh     pinned llama.cpp checkout
.github/workflows/        analyze + test, Linux engine smoke test with the real model, Android APK, iOS no-codesign build
```

## Stages

1. **Stage 0: Scaffold.** Flutter app, FFI plugin skeleton, CI for analyze/test.
2. **Stage 1: Native engine.** C ABI wrapper, Android CMake, iOS podspec + xcframework, Linux host build. Run a smoke test with the real model on Linux, from both a C++ test and Dart FFI. CI compiles for Android and iOS.
3. **Stage 2: Core services.** Model manager (resume, size check, import), image pipeline (EXIF orientation, resize to 2.4 MP "accurate" or 1 MP "fast"), PDF rendering at 200 dpi, OCR job queue with streaming and cancel, output parser, exporters (TXT, MD, HTML, DOCX, XLSX, CSV). Unit tests for all of these.
4. **Stage 3: UI/UX.** Material 3 theme, bundled Arabic fonts, English and Arabic UI (RTL), model-setup onboarding, home with recent scans, in-app camera, page review (reorder, rotate, crop), live streaming result, formatted/raw/edit views, copy/share/save, history, settings. Widget and screenshot tests.
5. **Stage 4: Device CI.** Android emulator integration tests, iOS simulator build, artifacts (APK, unsigned iOS build).
6. **Stage 5: iPhone Duo and foldables.** Adaptive two-pane layouts for the 7.6" inner display and the 5.4" cover display, hinge avoidance on Android foldables, state continuity on fold and unfold. Screenshot tests at Duo sizes.
