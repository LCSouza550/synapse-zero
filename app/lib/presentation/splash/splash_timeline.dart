import 'package:flutter/animation.dart';

double _unit(double value) => value < 0 ? 0 : (value > 1 ? 1 : value);

/// Linha do tempo da splash. Lógica pura: sem desenho, fácil de testar.
///
/// `t` é o tempo normalizado (0..1) de um único AnimationController.
/// O capacitor e o nome reagem à POSIÇÃO do feixe, não a tempos fixos,
/// o que mantém tudo sincronizado e sem pausas.
class SplashTimeline {
  SplashTimeline()
      : spinStart = _timeAt(capacitorAt - ringHalfSpan),
        spinEnd = _timeAt(capacitorAt + ringHalfSpan);

  static const Duration duration = Duration(milliseconds: 4200);

  /// Janela (fração de t) em que o feixe se move; o restante é a pausa final.
  static const double beamStart = 0.04;
  static const double beamEnd = 0.90;

  /// Posição do capacitor no percurso (0..1).
  static const double capacitorAt = 0.42;

  /// Metade do diâmetro do capacitor em fração do percurso.
  /// Vem de: raio (13% da largura) ÷ percurso (84% da largura) ≈ 0,155.
  /// Se mudar o raio ou o percurso no painter, atualize este valor.
  static const double ringHalfSpan = 0.155;

  /// O nome começa a surgir quando o feixe passa desta posição.
  static const double titleStartProgress = 0.62;

  /// Brilho que permanece aceso depois do pico (0..1).
  static const double sustainedGlow = 0.38;

  /// Duração da queda do brilho (fração de t).
  static const double glowDecay = 0.20;

  /// Duração da propagação do halo (fração de t) e atraso de cada onda.
  static const double haloSpan = 0.32;
  static const List<double> haloDelays = [0.0, 0.07];

  /// Instantes (fração de t) em que o feixe entra e sai do capacitor.
  final double spinStart;
  final double spinEnd;

  static double _beamAt(double t) {
    final k = _unit((t - beamStart) / (beamEnd - beamStart));
    return Curves.easeInOutSine.transform(k);
  }

  /// Instante em que o feixe atinge [progress] (busca binária; _beamAt é monotônica).
  static double _timeAt(double progress) {
    var low = beamStart;
    var high = beamEnd;
    for (var i = 0; i < 40; i++) {
      final mid = (low + high) / 2;
      if (_beamAt(mid) < progress) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return high;
  }

  /// Posição do feixe no percurso (0..1).
  double beamProgress(double t) => _beamAt(t);

  /// Voltas completas do capacitor (0..1). Gira enquanto o feixe o atravessa.
  double spinTurns(double t) {
    final k = _unit((t - spinStart) / (spinEnd - spinStart));
    return Curves.easeInOutCubic.transform(k);
  }

  /// Brilho do capacitor: sobe até o pico ao completar o giro,
  /// cai e se mantém em [sustainedGlow].
  double glow(double t) {
    if (t <= spinStart) return 0;
    if (t < spinEnd) {
      final k = (t - spinStart) / (spinEnd - spinStart);
      return Curves.easeInQuart.transform(k);
    }
    final k = _unit((t - spinEnd) / glowDecay);
    return 1.0 - (1.0 - sustainedGlow) * Curves.easeOutCubic.transform(k);
  }

  /// Progresso (0..1) de uma onda do halo, a partir do fim do giro.
  double haloProgress(double t, {double delay = 0}) {
    final k = _unit((t - spinEnd - delay) / haloSpan);
    return Curves.easeOutCubic.transform(k);
  }

  /// Opacidade do nome: depende da posição do feixe e chega a 1 quando ele termina.
  double titleOpacity(double t) {
    final p = beamProgress(t);
    final k = _unit((p - titleStartProgress) / (1.0 - titleStartProgress));
    return Curves.easeOut.transform(k);
  }
}