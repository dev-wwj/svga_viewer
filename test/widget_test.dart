import 'package:flutter_test/flutter_test.dart';
import 'package:svger/main.dart';

void main() {
  testWidgets('shows the Motion Preview empty workspace', (tester) async {
    await tester.pumpWidget(const MyApp());
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .text('A lightweight local previewer for motion and media assets.')
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.text('Motion Preview'), findsWidgets);
    expect(
      find.text('A lightweight local previewer for motion and media assets.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 1));
  });
}
