import '../document/ocr_document.dart';

enum ExportFormat {
  docx(
    'docx',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ),
  xlsx(
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ),
  txt('txt', 'text/plain'),
  md('md', 'text/markdown'),
  html('html', 'text/html'),
  csv('csv', 'text/csv');

  const ExportFormat(this.extension, this.mimeType);

  final String extension;
  final String mimeType;

  /// Formats that only carry the document's tables.
  bool get tablesOnly => this == xlsx || this == csv;

  /// The formats that suit [doc], best first:
  ///
  /// * tables: Word keeps text and tables together, Excel/CSV take the tables;
  /// * headings or lists: Word, then Markdown / HTML;
  /// * plain text: a text file.
  static List<ExportFormat> suggestionsFor(OcrDocument doc) {
    if (doc.hasTables) return const [docx, xlsx, html, md, csv, txt];
    if (doc.isStructured) return const [docx, md, html, txt];
    return const [txt, docx, html, md];
  }
}
