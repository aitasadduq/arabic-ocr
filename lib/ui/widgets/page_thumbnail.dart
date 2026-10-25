import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../models/scan.dart';

/// A small picture of a page from wherever it lives.
class PageThumbnail extends StatelessWidget {
  const PageThumbnail({
    super.key,
    required this.source,
    this.imagePath,
    this.quarterTurns = 0,
    this.fit = BoxFit.cover,
    this.cacheWidth = 480,
  });

  final PageSource source;

  /// The stored page image, preferred when present.
  final String? imagePath;
  final int quarterTurns;
  final BoxFit fit;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget placeholder() => ColoredBox(
      color: cs.surfaceContainerHigh,
      child: Icon(Icons.description_outlined, color: cs.outline),
    );
    final stored = imagePath;
    Widget image;
    var turns = quarterTurns;
    if (stored != null && File(stored).existsSync()) {
      // the stored image already has the rotation applied
      turns = 0;
      image = Image.file(
        File(stored),
        fit: fit,
        cacheWidth: cacheWidth,
        errorBuilder: (_, _, _) => placeholder(),
      );
    } else {
      image = switch (source) {
        FilePageSource(:final path) => Image.file(
          File(path),
          fit: fit,
          cacheWidth: cacheWidth,
          errorBuilder: (_, _, _) => placeholder(),
        ),
        AssetPageSource(:final asset) => Image.asset(
          asset,
          fit: fit,
          cacheWidth: cacheWidth,
        ),
        PdfPageSource(:final path, :final index) => PdfDocumentViewBuilder.file(
          path,
          builder: (context, document) => document == null
              ? placeholder()
              : ColoredBox(
                  color: Colors.white,
                  child: PdfPageView(
                    document: document,
                    pageNumber: index + 1,
                    maximumDpi: 72,
                  ),
                ),
        ),
      };
    }
    return turns % 4 == 0
        ? image
        : RotatedBox(quarterTurns: turns, child: image);
  }
}
