import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/document/ocr_document.dart';
import '../core/export/export_format.dart';
import '../core/export/office_exporters.dart';
import '../core/export/text_exporters.dart';

/// Builds export files and hands them to the system (save dialog, share
/// sheet, clipboard).
class ExportService {
  const ExportService();

  Uint8List build(
    OcrDocument doc,
    ExportFormat format, {
    required String title,
  }) => switch (format) {
    ExportFormat.txt => _utf8(TextExporters.toPlainText(doc)),
    ExportFormat.md => _utf8(TextExporters.toMarkdown(doc)),
    ExportFormat.html => _utf8(TextExporters.toHtml(doc, title: title)),
    ExportFormat.csv => _utf8(TextExporters.toCsv(doc)),
    ExportFormat.docx => OfficeExporters.toDocx(doc, title: title),
    ExportFormat.xlsx => OfficeExporters.toXlsx(doc),
  };

  static Uint8List _utf8(String s) => Uint8List.fromList(utf8.encode(s));

  /// A file name that is safe on every platform, keeping Arabic letters.
  static String fileName(String title, ExportFormat format) {
    var base = title.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), ' ').trim();
    base = base.replaceAll(RegExp(r'\s+'), ' ');
    if (base.length > 60) base = base.substring(0, 60).trim();
    if (base.isEmpty) base = 'ocr';
    return '$base.${format.extension}';
  }

  /// Opens the system "save to" dialog. Returns false when the user cancels.
  Future<bool> saveAs(
    OcrDocument doc,
    ExportFormat format, {
    required String title,
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName(title, format),
      bytes: build(doc, format, title: title),
      mimeType: format.mimeType,
    );
    return uri != null;
  }

  /// Opens the share sheet with the file attached.
  Future<void> share(
    OcrDocument doc,
    ExportFormat format, {
    required String title,
    Rect? origin,
  }) async {
    final dir = Directory(
      p.join((await getTemporaryDirectory()).path, 'exports'),
    );
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, fileName(title, format)));
    await file.writeAsBytes(build(doc, format, title: title), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: format.mimeType)],
        subject: title,
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  /// The whole document as plain text (tables tab-separated).
  Future<void> copyDocument(OcrDocument doc) => copyText(doc.plainText);

  /// A table as tab-separated rows, which paste as cells in spreadsheets.
  Future<void> copyTable(TableBlock table) => copyText(table.tsv);
}
