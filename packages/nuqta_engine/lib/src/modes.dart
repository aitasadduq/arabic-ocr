/// What the model is asked to write. The prompts are the ones Nuqta-OCR was
/// trained with (nuqta-ocr `src/nuqta/text.py`); changing them hurts accuracy.
enum NuqtaMode {
  /// Text with tashkeel only where it is printed.
  asWritten(
    'as-written',
    'Transcribe the Arabic text in this image exactly as written. '
        'Include only the diacritics (tashkeel) that are visible in the image.',
  ),

  /// Text without any tashkeel.
  bare(
    'bare',
    'Transcribe the Arabic text in this image without any diacritics.',
  ),

  /// Headings, paragraphs, lists and tables (HTML) in reading order.
  markdown(
    'markdown',
    'Convert this document to Markdown: headings, paragraphs, lists and '
        'tables in reading order. Include only the diacritics visible in the image.',
  );

  const NuqtaMode(this.id, this.prompt);

  final String id;
  final String prompt;

  static NuqtaMode fromId(String? id) =>
      values.firstWhere((m) => m.id == id, orElse: () => asWritten);
}
