import 'package:flutter_test/flutter_test.dart';
import 'package:synapsezero/presentation/splash/splash_timeline.dart';

void main() {
  const timeline = SplashTimeline();

  test('a sequência de instantes é ordenada', () {
    expect(SplashTimeline.approachStart, lessThan(SplashTimeline.contact));
    expect(SplashTimeline.contact, lessThan(SplashTimeline.connected));
    expect(SplashTimeline.connected, lessThan(SplashTimeline.glowPeak));
    expect(SplashTimeline.glowPeak, lessThan(SplashTimeline.beamEnd));
    expect(SplashTimeline.beamEnd, lessThan(1));
    expect(SplashTimeline.entryAt, lessThan(SplashTimeline.exitAt));
  });

  test('o conector é simétrico: está no centro do percurso', () {
    expect(
      (SplashTimeline.entryAt + SplashTimeline.exitAt) / 2,
      closeTo(0.5, 1e-9),
    );
  });

  test('o feixe é monotônico e vai de 0 a 1', () {
    var previous = -1.0;
    for (var i = 0; i <= 400; i++) {
      final value = timeline.beamProgress(i / 400);
      expect(value, greaterThanOrEqualTo(previous));
      previous = value;
    }
    expect(timeline.beamProgress(0), closeTo(0, 1e-9));
    expect(timeline.beamProgress(SplashTimeline.beamEnd), closeTo(1, 1e-9));
    expect(timeline.beamProgress(1), closeTo(1, 1e-9));
  });

  test('o feixe tem velocidade constante e só pára durante o giro', () {
    const dt = 0.01;
    double speed(double t) =>
        (timeline.beamProgress(t + dt) - timeline.beamProgress(t)) / dt;

    final expected = 1 / SplashTimeline.moveSpan;
    // Antes do contato.
    expect(speed(SplashTimeline.approachStart + 0.02), closeTo(expected, 1e-6));
    expect(speed(SplashTimeline.contact - 0.05), closeTo(expected, 1e-6));
    // Depois da conexão, inclusive no trecho final.
    expect(speed(SplashTimeline.connected + 0.01), closeTo(expected, 1e-6));
    expect(speed(SplashTimeline.beamEnd - 0.05), closeTo(expected, 1e-6));
    // Durante o giro o feixe está parado no ponto de contato.
    final mid = (SplashTimeline.contact + SplashTimeline.connected) / 2;
    expect(timeline.beamProgress(mid), closeTo(SplashTimeline.entryAt, 1e-9));
  });

  test('o feixe só entra no conector depois da conexão', () {
    expect(
      timeline.beamProgress(SplashTimeline.contact),
      closeTo(SplashTimeline.entryAt, 1e-9),
    );
    expect(
      timeline.beamProgress(SplashTimeline.connected),
      closeTo(SplashTimeline.entryAt, 1e-9),
    );
    expect(
      timeline.beamProgress(SplashTimeline.connected + 0.05),
      greaterThan(SplashTimeline.entryAt),
    );
  });

  test('o conector gira entre o contato e a conexão', () {
    expect(timeline.spinTurns(0), 0);
    expect(timeline.spinTurns(SplashTimeline.contact), closeTo(0, 1e-9));
    expect(timeline.spinTurns(SplashTimeline.connected), closeTo(1, 1e-9));
    expect(timeline.spinTurns(1), closeTo(1, 1e-9));
  });

  test('a barra interna só se conecta ao fim do giro', () {
    expect(timeline.link(SplashTimeline.contact), 0);
    expect(timeline.link(SplashTimeline.connected), closeTo(1, 1e-4));
    expect(timeline.link(1), closeTo(1, 1e-4));
  });

  test('o brilho estoura ao conectar e depois permanece aceso', () {
    expect(timeline.glow(0), 0);
    expect(timeline.glow(SplashTimeline.contact), 0);
    expect(
      timeline.glow(SplashTimeline.connected),
      closeTo(SplashTimeline.chargeGlow, 1e-9),
    );
    expect(timeline.glow(SplashTimeline.glowPeak), closeTo(1, 1e-9));
    expect(timeline.glow(1), closeTo(SplashTimeline.sustainedGlow, 1e-9));
  });

  test('o glow emitido se expande a partir da conexão', () {
    expect(timeline.pulse(SplashTimeline.connected), 0);
    expect(timeline.pulse(1), closeTo(1, 1e-9));
  });

  test('o nome só surge após o feixe sair do conector e termina com ele', () {
    expect(timeline.titleOpacity(0), 0);
    expect(timeline.titleOpacity(SplashTimeline.connected), 0);
    expect(timeline.titleOpacity(SplashTimeline.beamEnd), closeTo(1, 1e-9));
    var previous = -1.0;
    for (var i = 0; i <= 400; i++) {
      final value = timeline.titleOpacity(i / 400);
      expect(value, greaterThanOrEqualTo(previous));
      previous = value;
    }
  });
}
