import 'package:flutter_test/flutter_test.dart';
import 'package:nuqta_engine/nuqta_engine.dart';

void main() {
  group('NuqtaText.clean', () {
    test('drops think blocks and image placeholders', () {
      expect(
        NuqtaText.clean('<think>\nhmm\n</think>\n\nمرحبا<img>image here</img>'),
        'مرحبا',
      );
    });

    test('drops a wrapping code fence', () {
      expect(NuqtaText.clean('```markdown\n# عنوان\nنص\n```'), '# عنوان\nنص');
    });

    test('keeps inner fences', () {
      const t = 'a\n```\ncode\n```\nb';
      expect(NuqtaText.clean(t), t);
    });
  });

  group('NuqtaText.trimLoops', () {
    test('cuts a span repeated up to the end of the output', () {
      const unit = 'والله أعلم بالصواب ';
      final looped = 'بداية النص. ${unit * 30}';
      final trimmed = NuqtaText.trimLoops(looped);
      expect(trimmed.length, lessThan(looped.length ~/ 5));
      expect(trimmed, startsWith('بداية النص.'));
      expect(NuqtaText.looped(looped), isTrue);
    });

    test('keeps a few genuine repeats in the middle', () {
      const t = 'نعم نعم نعم نعم نعم نعم ثم انتهى الكلام هنا والحمد لله';
      expect(NuqtaText.trimLoops(t), t);
    });

    test('keeps MRZ filler', () {
      const mrz = 'P<EGYMOHAMED<<AHMED<<<<<<<<<<<<<<<<<<<<<<<<<<';
      expect(NuqtaText.trimLoops(mrz), mrz);
    });

    test('collapses a 200+ run of one character', () {
      final t = 'a${'ـ' * 250}b';
      expect(NuqtaText.trimLoops(t), 'aـb');
    });

    test('keeps a repeated long line only once when it repeats 10+ times', () {
      const line = 'هذا سطر طويل يتكرر كثيرا في المخرجات بلا داع حقيقي أبدا';
      final t = List.filled(12, line).join('\n');
      expect(
        NuqtaText.trimLoops(t).split('\n').where((l) => l == line).length,
        1,
      );
    });
  });

  group('NuqtaInputPolicy', () {
    test('scales pages to the target size, up or down', () {
      final up = NuqtaInputPolicy.targetSize(612, 792);
      expect(up.width * up.height, closeTo(2.4e6, 3000));
      final down = NuqtaInputPolicy.targetSize(3000, 4000);
      expect(down.width * down.height, closeTo(2.4e6, 3000));
      expect(down.width / down.height, closeTo(0.75, 0.001));
    });

    test('keeps crops at their size unless over the cap', () {
      expect(NuqtaInputPolicy.targetSize(800, 120), (width: 800, height: 120));
      final long = NuqtaInputPolicy.targetSize(6000, 600);
      expect(long.width * long.height, closeTo(2.4e6, 3000));
    });

    test('fast setting targets 1 MP', () {
      final s = NuqtaInputPolicy.targetSize(
        3000,
        4000,
        megapixels: NuqtaInputPolicy.fastMegapixels,
      );
      expect(s.width * s.height, closeTo(1e6, 2000));
    });
  });

  test('prompts match the trained ones', () {
    expect(
      NuqtaMode.bare.prompt,
      'Transcribe the Arabic text in this image without any diacritics.',
    );
    expect(NuqtaMode.fromId('markdown'), NuqtaMode.markdown);
    expect(NuqtaMode.fromId('nope'), NuqtaMode.asWritten);
  });
}
