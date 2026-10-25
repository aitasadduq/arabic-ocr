import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nuqta_engine/nuqta_engine.dart';

import '../app_scope.dart';
import '../models/scan.dart';
import '../services/page_loader.dart';
import 'labels.dart';
import 'screens/camera_screen.dart';
import 'screens/result_screen.dart';
import 'screens/review_screen.dart';

const _imageExtensions = [
  'jpg',
  'jpeg',
  'png',
  'webp',
  'heic',
  'heif',
  'bmp',
  'gif',
];

/// Bundled sample pages and the mode that suits each.
const samples = <(String asset, NuqtaMode mode)>[
  ('assets/samples/book.jpg', NuqtaMode.asWritten),
  ('assets/samples/table.jpg', NuqtaMode.markdown),
  ('assets/samples/passport.jpg', NuqtaMode.asWritten),
  ('assets/samples/old_book.jpg', NuqtaMode.markdown),
];

String sampleLabel(BuildContext context, String asset) {
  final l = context.l10n;
  if (asset.contains('table')) return l.sampleTable;
  if (asset.contains('passport')) return l.samplePassport;
  if (asset.contains('old_book')) return l.sampleOldBook;
  return l.sampleBook;
}

String newId() {
  final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final rnd = math.Random().nextInt(1 << 30).toRadixString(36);
  return '$now$rnd';
}

Future<void> pickFromPhotos(BuildContext context) async {
  final files = await ImagePicker().pickMultiImage(requestFullMetadata: false);
  if (files.isEmpty || !context.mounted) return;
  await openReview(context, [for (final f in files) FilePageSource(f.path)]);
}

Future<void> pickFromFiles(BuildContext context) async {
  final sources = await pickPageFiles(context);
  if (sources == null || sources.isEmpty || !context.mounted) return;
  await openReview(context, sources);
}

/// PDFs become one source per page; images one source each.
Future<List<PageSource>?> pickPageFiles(BuildContext context) async {
  final loader = context.services.loader;
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', ..._imageExtensions],
  );
  final out = <PageSource>[];
  for (final f in picked) {
    final path = f.path;
    if (path == null) continue;
    if ((f.extension ?? '').toLowerCase() == 'pdf') {
      try {
        final n = await loader.pdfPageCount(path);
        out.addAll([for (var i = 0; i < n; i++) PdfPageSource(path, i)]);
      } on PageLoadException catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text(pageErrorText(l, e.kind.name))),
        );
      }
    } else {
      out.add(FilePageSource(path));
    }
  }
  return out;
}

Future<void> openCamera(BuildContext context) async {
  final paths = await Navigator.of(context).push<List<String>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const CameraScreen(),
    ),
  );
  if (paths == null || paths.isEmpty || !context.mounted) return;
  await openReview(context, [for (final p in paths) FilePageSource(p)]);
}

Future<void> openReview(BuildContext context, List<PageSource> sources) =>
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ReviewScreen(initial: sources)));

/// Starts reading [scan] and shows it.
Future<void> startScan(
  BuildContext context,
  Scan scan, {
  bool replace = false,
}) {
  final s = context.services;
  if (!s.models.isReady) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.modelNeeded)));
    return Future.value();
  }
  s.runner.run(scan);
  final route = MaterialPageRoute<void>(
    builder: (_) => ResultScreen(scan: scan),
  );
  return replace
      ? Navigator.of(context).pushReplacement(route)
      : Navigator.of(context).push(route);
}

/// Reads a bundled sample page straight away.
Future<void> readSample(BuildContext context, String asset, NuqtaMode mode) {
  final s = context.services;
  final scan = Scan(
    id: newId(),
    createdAt: DateTime.now(),
    mode: mode,
    quality: s.settings.quality,
    title: sampleLabel(context, asset),
    pages: [ScanPage(id: 'p1', source: AssetPageSource(asset))],
  );
  return startScan(context, scan);
}
