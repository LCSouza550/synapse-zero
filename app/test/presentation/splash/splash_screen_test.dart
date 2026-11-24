import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synapsezero/application/audio/splash_audio.dart';
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

  testWidgets('a animação só parte depois que o som realmente começou', (tester) async {
    final audio = _ControlledAudio();
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(onFinished: () {}, audio: audio)),
    );
    await tester.pump();
    await tester.pump();
    expect(audio.playCalled, isTrue);

    // Som ainda não começou: o relógio da animação está parado.
    await tester.pump(const Duration(seconds: 2));
    expect(tester.hasRunningAnimations, isFalse);

    audio.started.complete();
    await tester.pump();
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
  });
}

class _ControlledAudio implements SplashAudio {
  final Completer<void> started = Completer<void>();
  bool playCalled = false;

  @override
  Future<void> prepare() async {}

  @override
  Future<void> playIntro() {
    playCalled = true;
    return started.future;
  }

  @override
  Future<void> dispose() async {}
}
