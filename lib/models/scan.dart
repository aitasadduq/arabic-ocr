import 'package:nuqta_engine/nuqta_engine.dart';

import '../core/document/document_parser.dart';
import '../core/document/ocr_document.dart';

/// How large the page is shown to the model.
enum ReadQuality {
  /// 2.4 MP, the size the model was trained at.
  accurate(NuqtaInputPolicy.accurateMegapixels),

  /// 1 MP: about twice as fast, slightly less accurate on dense pages.
  fast(NuqtaInputPolicy.fastMegapixels);

  const ReadQuality(this.megapixels);
  final double megapixels;

  static ReadQuality fromName(String? n) =>
      values.firstWhere((q) => q.name == n, orElse: () => accurate);
}

/// Where a page comes from.
sealed class PageSource {
  const PageSource();

  Map<String, dynamic> toJson();

  static PageSource fromJson(Map<String, dynamic> j) => switch (j['type']) {
    'pdf' => PdfPageSource(j['path'] as String, j['index'] as int),
    'asset' => AssetPageSource(j['asset'] as String),
    _ => FilePageSource(j['path'] as String),
  };
}

/// An image file (camera, photo library, Files).
final class FilePageSource extends PageSource {
  const FilePageSource(this.path);
  final String path;

  @override
  Map<String, dynamic> toJson() => {'type': 'file', 'path': path};
}

/// One page of a PDF ([index] is 0-based).
final class PdfPageSource extends PageSource {
  const PdfPageSource(this.path, this.index);
  final String path;
  final int index;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'pdf',
    'path': path,
    'index': index,
  };
}

/// A bundled sample page.
final class AssetPageSource extends PageSource {
  const AssetPageSource(this.asset);
  final String asset;

  @override
  Map<String, dynamic> toJson() => {'type': 'asset', 'asset': asset};
}

enum PageStatus {
  queued,
  preparing,
  reading,
  writing,
  done,
  cancelled,
  failed;

  bool get isActive => this == preparing || this == reading || this == writing;
  bool get isFinished => this == done || this == cancelled || this == failed;
}

class ScanPage {
  ScanPage({
    required this.id,
    required this.source,
    this.quarterTurns = 0,
    this.status = PageStatus.queued,
    this.text = '',
    this.imagePath,
    this.error,
    this.seconds,
    this.firstWordsSeconds,
    this.tokens,
  });

  factory ScanPage.fromJson(Map<String, dynamic> j) => ScanPage(
    id: j['id'] as String,
    source: PageSource.fromJson((j['source'] as Map).cast<String, dynamic>()),
    quarterTurns: (j['quarterTurns'] as int?) ?? 0,
    status: PageStatus.values.firstWhere(
      (s) => s.name == j['status'],
      orElse: () => PageStatus.queued,
    ),
    text: (j['text'] as String?) ?? '',
    imagePath: j['imagePath'] as String?,
    error: j['error'] as String?,
    seconds: (j['seconds'] as num?)?.toDouble(),
    firstWordsSeconds: (j['firstWordsSeconds'] as num?)?.toDouble(),
    tokens: j['tokens'] as int?,
  );

  final String id;
  PageSource source;

  /// Extra clockwise rotation chosen by the user, in quarter turns.
  int quarterTurns;
  PageStatus status;

  /// What the model wrote (cleaned once the page is done).
  String text;

  /// The page image as the model saw it (stored with the scan), once read.
  String? imagePath;
  String? error;
  double? seconds;
  double? firstWordsSeconds;
  int? tokens;

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source.toJson(),
    'quarterTurns': quarterTurns,
    // a page interrupted mid-read is read again next time
    'status': status.isActive ? PageStatus.queued.name : status.name,
    'text': text,
    'imagePath': ?imagePath,
    'error': ?error,
    'seconds': ?seconds,
    'firstWordsSeconds': ?firstWordsSeconds,
    'tokens': ?tokens,
  };
}

class Scan {
  Scan({
    required this.id,
    required this.createdAt,
    required this.mode,
    required this.quality,
    required this.pages,
    this.title = '',
  });

  factory Scan.fromJson(Map<String, dynamic> j) => Scan(
    id: j['id'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    mode: NuqtaMode.fromId(j['mode'] as String?),
    quality: ReadQuality.fromName(j['quality'] as String?),
    title: (j['title'] as String?) ?? '',
    pages: [
      for (final p in (j['pages'] as List))
        ScanPage.fromJson((p as Map).cast<String, dynamic>()),
    ],
  );

  final String id;
  final DateTime createdAt;
  NuqtaMode mode;
  ReadQuality quality;
  String title;
  final List<ScanPage> pages;

  bool get isStructured => mode == NuqtaMode.markdown;
  bool get isFinished => pages.every((p) => p.status.isFinished);
  int get doneCount => pages.where((p) => p.status == PageStatus.done).length;

  /// The pages read so far, parsed.
  OcrDocument get document => OcrDocument([
    for (final p in pages)
      if (p.text.trim().isNotEmpty)
        DocumentParser.parse(p.text, structured: isStructured),
  ], title: title);

  DocPage pageDocument(ScanPage p) =>
      DocumentParser.parse(p.text, structured: isStructured);

  /// A short excerpt for lists.
  String get preview {
    for (final p in pages) {
      final t = p.text.replaceAll(RegExp(r'<[^>]+>|[#*|>-]'), ' ').trim();
      if (t.isNotEmpty) return t.replaceAll(RegExp(r'\s+'), ' ');
    }
    return '';
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'mode': mode.id,
    'quality': quality.name,
    'title': title,
    'pages': [for (final p in pages) p.toJson()],
  };
}
