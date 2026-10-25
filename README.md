# Arabic OCR

An offline Arabic OCR app for Android and iOS, built with Flutter. It reads text, tashkeel (diacritics) and tables from camera photos, images and PDFs. The reading runs on the phone with the open [Nuqta-OCR](https://github.com/SalahAlHaismawi/nuqta-ocr) 0.8B model on llama.cpp. Pages never leave the device.

| | |
|---|---|
| **Input** | In-app camera (several pages in a row, flash, tap to focus), photo library, Files (PDF and images). Before reading you can reorder, rotate, crop and select pages. |
| **Modes** | *As written* keeps the tashkeel printed on the page. *No tashkeel* gives plain text. *Document* gives headings, lists and tables. |
| **Output** | Text streams in live as the model writes. You get a formatted view (right-to-left tables with merged cells) or the raw text, and you can edit it. |
| **Copy / save** | Copy all text, or copy a table as tab-separated rows that paste into spreadsheets. Save or share a file in the format that fits the content: Word (.docx) for text and tables, Excel (.xlsx) for tables, plain text, Markdown, HTML or CSV. |
| **UI** | English and Arabic (RTL), light and dark. Adaptive layouts for phones, the iPhone Duo (cover and unfolded), Android foldables (hinge-aware) and tablets. |

## The model

The app downloads the model once: `nuqta-ocr-0.8b-Q4_K_M.gguf` and its vision projector, about 765 MB in total, from [Hugging Face](https://huggingface.co/SalahALHaismawi/Nuqta-OCR-0.8B-GGUF). The download is resumable and keeps going in the background. Setup also offers **Import model files** for devices that are never online.

Inference uses the upstream C++ engine (`packages/nuqta_engine/src/upstream`). It runs on the CPU on Android, picking the best ARM backend for the phone at run time, and on the GPU through Metal on iPhone. Upstream asks for Android 9+ (64-bit, ~2 GB free RAM) and recommends an iPhone 13 or newer.

## Building

You need Flutter 3.47+.

```bash
# Android: Gradle builds llama.cpp with the NDK (it fetches the pinned commit itself)
flutter build apk --release --split-per-abi --target-platform android-arm64

# iOS (macOS with Xcode and CMake): build the llama.cpp framework once, then
packages/nuqta_engine/tool/build_ios_xcframework.sh
flutter build ios
```

## Tests and CI

`.github/workflows/ci.yml` runs on every push:

| Job | What it checks |
|---|---|
| Analyze & unit tests | Format, analyzer, parser and exporters (tested on real model outputs), services, widgets, adaptive layouts |
| Engine on Linux with the real model | Builds the native engine and runs the real model through `dart:ffi`: streaming, a table read as HTML, cancel |
| Android APK / iOS build | Release builds. The APKs and an unsigned IPA are uploaded as artifacts. |
| Android emulator | Integration tests on a device: first run, image and PDF decoding, exports, then the model downloaded with the app's own downloader, loaded, and reading a page |
| iOS simulator | Integration tests on the simulator |
| UI screenshots | Key screens at phone, iPhone Duo and tablet sizes, in English/Arabic and light/dark, uploaded as an artifact |

Locally:

```bash
flutter test                                                    # unit + widget
SCREENSHOTS=1 flutter test test/screenshots_test.dart --update-goldens
flutter test integration_test/app_test.dart -d <device>         # on a device
```

## Project layout

```
lib/core/            document model, Nuqta Markdown/HTML parser, exporters (pure Dart)
lib/services/        model download, page loading (EXIF, PDF), reading queue, history
lib/ui/              screens, widgets, adaptive layouts, theme
packages/nuqta_engine/  FFI plugin: upstream engine + C ABI + Android/iOS builds
docs/PLAN.md         the staged plan
```

## Credits and licenses

* Nuqta-OCR model, engine, prompts and sample pages: Salah AlHaismawi, Mohamed Saleh Tulib, Ahmed ElSayed Mohamed Ibrahim. Apache-2.0.
* llama.cpp / ggml: MIT.
* Fonts (IBM Plex Sans, Noto Sans Arabic, Noto Naskh Arabic, Source Serif 4): SIL Open Font License.

This app is Apache-2.0 (see `LICENSE`).
