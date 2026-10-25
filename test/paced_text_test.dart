import 'package:arabic_ocr/ui/widgets/paced_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stopwatch the test moves by hand.
class FakeClock implements Stopwatch {
  int micros = 0;
  bool running = false;

  void advance(Duration d) => micros += d.inMicroseconds;

  @override
  int get elapsedMicroseconds => micros;
  @override
  bool get isRunning => running;
  @override
  void start() => running = true;
  @override
  void stop() => running = false;
  @override
  void reset() => micros = 0;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeClock clock;
  late PacedText paced;
  setUp(() {
    clock = FakeClock();
    paced = PacedText(const TestVSync(), clock: clock);
  });
  tearDown(() => paced.dispose());

  void frames(int n, {Duration every = const Duration(milliseconds: 16)}) {
    for (var i = 0; i < n; i++) {
      clock.advance(every);
      paced.tick();
    }
  }

  test('reveals text gradually and never goes backwards', () {
    paced.update('أ' * 300, finished: false);
    var last = 0;
    for (var i = 0; i < 100; i++) {
      frames(1);
      expect(paced.text.length, greaterThanOrEqualTo(last));
      last = paced.text.length;
      if (i == 9) {
        // after 160 ms part of the text is showing, not all of it
        expect(last, inExclusiveRange(0, 300));
      }
    }
    expect(last, 300);
  });

  test('a pause between bursts does not make the text jump back', () {
    paced.update('أ' * 50, finished: false);
    frames(200);
    expect(paced.caughtUp, isTrue);
    final shown = paced.text.length;
    // the model looks at the next strip for two seconds
    clock.advance(const Duration(seconds: 2));
    paced.update('أ' * 120, finished: false);
    frames(1);
    expect(paced.text.length, greaterThanOrEqualTo(shown));
    frames(300);
    expect(paced.text.length, 120);
  });

  test('finishing speeds up to show the rest quickly', () {
    paced.update('ب' * 2000, finished: false);
    frames(5);
    paced.update('ب' * 2000, finished: true);
    frames(30); // about half a second
    expect(paced.text.length, 2000);
  });

  test('replaced text is shown at once; reset starts over', () {
    paced.update('abcdef', finished: false);
    frames(3);
    paced.update('xyz', finished: true);
    expect(paced.text, 'xyz');
    paced.reset();
    expect(paced.text, '');
    paced.update('new page', finished: false);
    expect(paced.text.length, lessThan('new page'.length));
  });

  test('never splits a surrogate pair', () {
    paced.update('😀😀😀😀', finished: true);
    paced.flush();
    expect(paced.text, '😀😀😀😀');
  });
}
