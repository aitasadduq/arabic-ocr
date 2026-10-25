import 'package:arabic_ocr/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.textContaining('engine'), findsOneWidget);
  });
}
