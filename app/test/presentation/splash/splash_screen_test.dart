import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synapsezero/presentation/splash/splash_screen.dart';

void main() {
  testWidgets('chama onFinished ao término da animação', (tester) async {
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(onFinished: () => finished++)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(finished, 0);

    await tester.pumpAndSettle();
    expect(finished, 1);
  });
}