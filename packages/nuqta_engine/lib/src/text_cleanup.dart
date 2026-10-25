/// Output clean-up and loop trimming, ported from nuqta-ocr `src/nuqta/text.py`.
abstract final class NuqtaText {
  static final _think = RegExp(r'<think>.*?</think>', dotAll: true);
  static final _fence = RegExp(r'^```\w*\n?|\n?```$');
  static final _imageTag = RegExp(r'<img>image here</img>');
  static final _charRun = RegExp(r'([^\s<])\1{199,}');
  static final _cycle = RegExp(r'(.{8,200}?)(?:\s*\1){2,}', dotAll: true);
  static final _spaces = RegExp(r'\s+');

  /// A reading that loses more than this to [trimLoops] counts as looped.
  static const loopChars = 200;
  static const _endRepeats = 5;
  static const _runawayRepeats = 20;
  static const _lineRepeats = 10;

  /// Drops reasoning blocks, image placeholders and a wrapping code fence.
  static String clean(String text) {
    var t = text.replaceAll(_think, '').replaceAll(_imageTag, '').trim();
    return t.replaceAll(_fence, '').trim();
  }

  /// Removes runaway repetition only. Genuine repeats stay: identical table
  /// rows, dotted form lines, refrains and MRZ filler («<<<<»).
  static String trimLoops(String text) {
    var t = text.replaceAllMapped(_charRun, (m) => m[1]!);
    String? prev;
    while (prev != t) {
      prev = t;
      final input = t;
      final end = input.trimRight().length - 1;
      t = input.replaceAllMapped(_cycle, (m) {
        final unit = m[1]!;
        final whole = m[0]!;
        if (unit.replaceAll('<', '').trim().isEmpty) return whole; // MRZ filler
        final reps = whole.length / (unit.isEmpty ? 1 : unit.length);
        final atEnd = m.end >= end;
        return (atEnd && reps >= _endRepeats) || reps >= _runawayRepeats
            ? unit
            : whole;
      });
    }
    final lines = t.split('\n');
    final keys = [for (final l in lines) l.replaceAll(_spaces, ' ').trim()];
    final count = <String, int>{};
    for (final k in keys) {
      count[k] = (count[k] ?? 0) + 1;
    }
    final seen = <String>{};
    final out = <String>[];
    for (var i = 0; i < lines.length; i++) {
      final k = keys[i];
      if (k.length >= 40 && count[k]! >= _lineRepeats && seen.contains(k)) {
        continue;
      }
      seen.add(k);
      out.add(lines[i]);
    }
    return out.join('\n');
  }

  static bool looped(String text) =>
      text.length - trimLoops(text).length > loopChars;

  /// [clean] then [trimLoops] when the reading looped.
  static String finish(String text) {
    final c = clean(text);
    return looped(c) ? trimLoops(c) : c;
  }
}
