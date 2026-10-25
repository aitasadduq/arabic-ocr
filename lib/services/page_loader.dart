import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:nuqta_engine/nuqta_engine.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/scan.dart';

/// Upright RGBA pixels at the size the model should see.
class PreparedImage {
  const PreparedImage(this.rgba, this.width, this.height);

  final Uint8List rgba;
  final int width;
  final int height;
}

class PageLoadException implements Exception {
  const PageLoadException(this.kind, [this.detail]);

  final PageLoadError kind;
  final String? detail;

  @override
  String toString() =>
      'PageLoadException($kind${detail == null ? '' : ': $detail'})';
}

enum PageLoadError { unreadableImage, missingFile, pdfPassword, pdfUnreadable }

/// Turns page sources into model input: decodes with the platform codecs
/// (EXIF orientation applied), renders PDF pages at 200 dpi, applies the
/// user's rotation and the model's size policy.
class PageLoader {
  final _pdfs = <String, Future<PdfDocument>>{};

  Future<PreparedImage> load(
    PageSource source, {
    required double megapixels,
    int quarterTurns = 0,
  }) async {
    final PreparedImage image = switch (source) {
      FilePageSource(:final path) => await _encoded(
        await _readFile(path),
        megapixels,
      ),
      AssetPageSource(:final asset) => await _encoded(
        (await rootBundle.load(asset)).buffer.asUint8List(),
        megapixels,
      ),
      PdfPageSource(:final path, :final index) => await _pdfPage(
        path,
        index,
        megapixels,
      ),
    };
    return quarterTurns % 4 == 0 ? image : rotate(image, quarterTurns);
  }

  Future<Uint8List> _readFile(String path) async {
    final f = File(path);
    if (!await f.exists()) {
      throw const PageLoadException(PageLoadError.missingFile);
    }
    return f.readAsBytes();
  }

  Future<PreparedImage> _encoded(Uint8List bytes, double megapixels) async {
    ui.Codec codec;
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      codec = await ui.instantiateImageCodecWithSize(
        buffer,
        getTargetSize: (w, h) {
          final t = NuqtaInputPolicy.targetSize(w, h, megapixels: megapixels);
          return ui.TargetImageSize(width: t.width, height: t.height);
        },
      );
    } catch (e) {
      throw PageLoadException(PageLoadError.unreadableImage, '$e');
    }
    final frame = await codec.getNextFrame();
    codec.dispose();
    final image = frame.image;
    try {
      final data = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (data == null) {
        throw const PageLoadException(PageLoadError.unreadableImage);
      }
      return PreparedImage(
        data.buffer.asUint8List(),
        image.width,
        image.height,
      );
    } finally {
      image.dispose();
    }
  }

  Future<PdfDocument> _openPdf(String path) {
    return _pdfs.putIfAbsent(path, () async {
      await pdfrxFlutterInitialize();
      try {
        return await PdfDocument.openFile(path);
      } on PdfPasswordException {
        throw const PageLoadException(PageLoadError.pdfPassword);
      } catch (e) {
        throw PageLoadException(PageLoadError.pdfUnreadable, '$e');
      }
    });
  }

  /// Number of pages in a PDF (opens and caches it).
  Future<int> pdfPageCount(String path) async {
    try {
      return (await _openPdf(path)).pages.length;
    } catch (_) {
      // a failed open must not stay cached
      _pdfs.remove(path);
      rethrow;
    }
  }

  Future<PreparedImage> _pdfPage(
    String path,
    int index,
    double megapixels,
  ) async {
    final doc = await _openPdf(path);
    if (index < 0 || index >= doc.pages.length) {
      throw const PageLoadException(
        PageLoadError.pdfUnreadable,
        'no such page',
      );
    }
    final page = doc.pages[index];
    const scale = NuqtaInputPolicy.pdfDpi / 72;
    final w = math.max(1, (page.width * scale).round());
    final h = math.max(1, (page.height * scale).round());
    final t = NuqtaInputPolicy.targetSize(w, h, megapixels: megapixels);
    final rendered = await page.render(
      fullWidth: t.width.toDouble(),
      fullHeight: t.height.toDouble(),
      backgroundColor: 0xffffffff,
    );
    if (rendered == null) {
      throw const PageLoadException(
        PageLoadError.pdfUnreadable,
        'render failed',
      );
    }
    try {
      return PreparedImage(
        bgraToRgba(rendered.pixels),
        rendered.width,
        rendered.height,
      );
    } finally {
      rendered.dispose();
    }
  }

  Future<void> closePdf(String path) async {
    final doc = _pdfs.remove(path);
    if (doc != null) await (await doc).dispose();
  }

  Future<void> closeAll() async {
    for (final path in _pdfs.keys.toList()) {
      await closePdf(path);
    }
  }

  static Uint8List bgraToRgba(Uint8List bgra) {
    final out = Uint8List(bgra.length);
    for (var i = 0; i + 3 < bgra.length; i += 4) {
      out[i] = bgra[i + 2];
      out[i + 1] = bgra[i + 1];
      out[i + 2] = bgra[i];
      out[i + 3] = bgra[i + 3];
    }
    return out;
  }

  /// Rotates RGBA pixels clockwise by [quarterTurns].
  static PreparedImage rotate(PreparedImage src, int quarterTurns) {
    final q = quarterTurns % 4;
    if (q == 0) return src;
    final w = src.width, h = src.height;
    final ow = q == 2 ? w : h, oh = q == 2 ? h : w;
    final inp = src.rgba.buffer.asUint32List(src.rgba.offsetInBytes, w * h);
    final out = Uint32List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final int nx, ny;
        switch (q) {
          case 1:
            nx = h - 1 - y;
            ny = x;
          case 2:
            nx = w - 1 - x;
            ny = h - 1 - y;
          default:
            nx = y;
            ny = w - 1 - x;
        }
        out[ny * ow + nx] = inp[y * w + x];
      }
    }
    return PreparedImage(out.buffer.asUint8List(), ow, oh);
  }

  /// A JPEG of the prepared page, stored with the scan for display.
  static Future<Uint8List> encodePreview(PreparedImage image) =>
      compute(_encodeJpg, (image.rgba, image.width, image.height));

  static Uint8List _encodeJpg((Uint8List, int, int) args) {
    final (rgba, w, h) = args;
    final im = img.Image.fromBytes(
      width: w,
      height: h,
      bytes: rgba.buffer,
      bytesOffset: rgba.offsetInBytes,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    // drop alpha onto white so transparent PNGs do not turn black
    final flat = img.Image(width: w, height: h)
      ..clear(img.ColorRgb8(255, 255, 255));
    img.compositeImage(flat, im);
    return img.encodeJpg(flat, quality: 85);
  }
}
