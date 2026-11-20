import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synapsezero/presentation/splash/splash_screen.dart';

void main() {
  testWidgets('splash mostra o nome e avisa ao terminar', (tester) async {
    var finished = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: SplashScreen(playSound: false, onFinished: () => finished++),
        ),
      ),
    );

    await tester.pump(); // dispara a animação
    await tester.pump(const Duration(milliseconds: 2800));
    expect(find.text('SYNAPSE'), findsOneWidget);
    expect(finished, 0);

    await tester.pump(const Duration(milliseconds: 2000));
    expect(finished, 1);
  });

  testWidgets('tocar na splash pula a animação uma única vez', (tester) async {
    var finished = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: SplashScreen(playSound: false, onFinished: () => finished++),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(SplashScreen));
    await tester.pump(const Duration(milliseconds: 5000));
    expect(finished, 1);
  });
}
