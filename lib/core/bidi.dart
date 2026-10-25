/// Direction of a piece of text from its first strong character.
abstract final class Bidi {
  /// True when the first strong character is right-to-left (Arabic, Hebrew,
  /// Syriac, Thaana, N'Ko...). Text with no strong characters (digits,
  /// punctuation) counts as right-to-left, the reading direction of the app's
  /// documents.
  static bool isRtl(String text) {
    for (final r in text.runes) {
      if (_isRtlChar(r)) return true;
      if (_isLtrChar(r)) return false;
    }
    return true;
  }

  static bool _isRtlChar(int r) =>
      (r >= 0x0590 && r <= 0x08FF) ||
      (r >= 0xFB1D && r <= 0xFDFF) ||
      (r >= 0xFE70 && r <= 0xFEFF) ||
      (r >= 0x10800 && r <= 0x10FFF) ||
      (r >= 0x1E800 && r <= 0x1EFFF);

  static bool _isLtrChar(int r) {
    if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A)) return true;
    if (r < 0xC0) return false;
    // Latin-1 letters and the rest of the BMP's alphabetic blocks, excluding
    // the RTL ranges, combining marks and general punctuation
    if (r >= 0x0300 && r <= 0x036F) return false;
    if (r >= 0x2000 && r <= 0x2BFF) return false;
    if (r >= 0x3000 && r <= 0x303F) return false;
    if (r == 0xD7 || r == 0xF7) return false;
    return !_isRtlChar(r);
  }

  /// True when most of the document's lines read right to left.
  static bool mostlyRtl(Iterable<String> lines) {
    var rtl = 0, ltr = 0;
    for (final l in lines) {
      if (l.trim().isEmpty) continue;
      isRtl(l) ? rtl++ : ltr++;
    }
    return rtl >= ltr;
  }
}
