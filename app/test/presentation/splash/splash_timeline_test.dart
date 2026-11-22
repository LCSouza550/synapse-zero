import 'package:flutter_test/flutter_test.dart';
import 'package:synapsezero/presentation/splash/splash_timeline.dart';

void main() {
  final timeline = SplashTimeline();

  test('o feixe é monotônico e vai de 0 a 1', () {
    var previous = -1.0;
    for (var i = 0; i <= 200; i++) {
      final value = timeline.beamProgress(i / 200);
      expect(value, greaterThanOrEqualTo(previous));
      previous = value;
    }
    expect(timeline.beamProgress(0), closeTo(0, 1e-9));
    expect(timeline.beamProgress(1), closeTo(1, 1e-9));
  });

  test('o giro acontece antes do nome e dentro do percurso', () {
    expect(timeline.spinStart, lessThan(timeline.spinEnd));
    expect(timeline.spinEnd, lessThan(SplashTimeline.beamEnd));
    final titleStart = timeline.titleOpacity(timeline.spinEnd);
    expect(titleStart, 0);
  });

  test('o capacitor completa exatamente uma volta', () {
    expect(timeline.spinTurns(0), 0);
    expect(timeline.spinTurns(timeline.spinStart), closeTo(0, 1e-9));
    expect(timeline.spinTurns(timeline.spinEnd), closeTo(1, 1e-9));
    expect(timeline.spinTurns(1), closeTo(1, 1e-9));
  });

  test('o brilho atinge o pico ao fim do giro e depois se mantém aceso', () {
    expect(timeline.glow(0), 0);
    expect(timeline.glow(timeline.spinEnd), closeTo(1, 1e-9));
    expect(timeline.glow(1), closeTo(SplashTimeline.sustainedGlow, 1e-9));
    expect(timeline.glow(1), greaterThan(0));
  });

  test('o nome termina visível junto com o feixe', () {
    expect(timeline.titleOpacity(0), 0);
    expect(timeline.titleOpacity(SplashTimeline.beamEnd), closeTo(1, 1e-9));
    var previous = -1.0;
    for (var i = 0; i <= 200; i++) {
      final value = timeline.titleOpacity(i / 200);
      expect(value, greaterThanOrEqualTo(previous));
      previous = value;
    }
  });
}