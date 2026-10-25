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

## Stages and status

| Stage | Scope | Status / evidence |
|---|---|---|
| 0. Scaffold | Flutter app, FFI plugin, CI | Done |
| 1. Native engine | C ABI over the upstream engine, Android CMake, iOS xcframework + podspec, Linux host build | Done. CI runs the real model through `dart:ffi` on Linux (streaming, a table read with `rowspan`, cancel). Android APK and iOS builds are green. |
| 2. Core services | Model download/import, page loading (EXIF, PDF at 200 dpi), reading queue, parser, exporters | Done. Unit tests cover these, using real 0.8B outputs. DOCX/XLSX were checked by rendering them in LibreOffice. |
| 3. UI/UX | Setup, home, camera, review, live result, export sheet, settings; English/Arabic, light/dark | Done. Widget tests and screenshots (CI artifact `ui-screenshots`). |
| 4. Device CI | Android emulator + iOS simulator integration tests | Android emulator: the model was downloaded with the app's downloader, loaded and read a page with tashkeel. iOS simulator: decoding, PDFium and exports pass. |
| 5. iPhone Duo / foldables | Size classes, hinge-aware split, page image beside the text, camera panel, state kept across fold/unfold | Done. Tests (`test/adaptive_test.dart`) and screenshots at Duo sizes. |

## Known limits / next steps

* **Speed on the Android emulator:** first words came after about 230 s, at 9.6 tok/s. The x86_64 build is a baseline CPU backend meant only for emulators. Phones use ARM variants picked at run time (dotprod/i8mm/SVE, KleidiAI). They have not been measured on real hardware in CI.
* **Not tested on physical devices:** the camera, the photo and file pickers, the share sheet and the cropper are covered by builds and manual reasoning only.
* **iOS distribution:** CI produces an unsigned IPA. Installing it needs your own signing (Xcode with an Apple ID, or a developer account).
* **Ideas:** "Open with / Share to" this app for PDFs and images; drag and drop on large screens; re-read a looping page at native size, as the Python library does.
