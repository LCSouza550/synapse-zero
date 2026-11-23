import 'package:flutter/animation.dart';

double _unit(double value) => value < 0 ? 0 : (value > 1 ? 1 : value);

/// Linha do tempo da splash. Lógica pura: sem desenho, fácil de testar.
///
/// `t` é o tempo normalizado (0..1) de um único AnimationController.
///
/// Sequência:
/// 1. O feixe percorre a linha até tocar o conector.
/// 2. No contato, o conector gira e a barra interna se alinha ao feixe:
///    a conexão é estabelecida.
/// 3. No instante da conexão, o conector emite um glow que cai e permanece.
/// 4. O feixe passa pelo conector e segue até o fim; o nome surge e termina
///    junto com o feixe. Depois há uma pausa curta.
///
/// **Velocidade constante:** o feixe anda sempre com a mesma velocidade
/// (progresso linear no tempo). A única parada é o giro do conector.
///
/// As frações de layout abaixo são a fonte única: o painter as usa para
/// desenhar e esta classe as usa para calcular os tempos.
class SplashTimeline {
  const SplashTimeline();

  static const Duration duration = Duration(milliseconds: 4200);

  // --- Layout (frações da largura da tela) ---
  static const double startFrac = 0.08;
  static const double endFrac = 0.92;
  static const double radiusFrac = 0.104;
  static const double centerFrac = 0.5;

  /// Posição (0..1 no percurso) em que o feixe toca o conector.
  static const double entryAt =
      (centerFrac - radiusFrac - startFrac) / (endFrac - startFrac);

  /// Posição (0..1 no percurso) em que o feixe deixa o conector.
  static const double exitAt =
      (centerFrac + radiusFrac - startFrac) / (endFrac - startFrac);

  // --- Tempo (frações de t) ---
  static const double approachStart = 0.04;
  static const double beamEnd = 0.88;

  /// Duração do giro (a única parada do feixe).
  static const double spinSpan = 0.16;

  /// Tempo gasto para percorrer o percurso inteiro, sem contar o giro.
  static const double moveSpan = beamEnd - approachStart - spinSpan;

  /// O feixe toca o conector e o giro começa.
  static const double contact = approachStart + entryAt * moveSpan;

  /// O giro termina: conexão estabelecida.
  static const double connected = contact + spinSpan;

  /// Janela do estalo de brilho logo após a conexão.
  static const double glowSwell = 0.03;

  /// Instante em que o brilho atinge o pico.
  static const double glowPeak = connected + glowSwell;

  /// Brilho do conector durante o giro, antes da conexão (0..1).
  static const double chargeGlow = 0.25;

  /// Brilho que permanece aceso depois do pico (0..1).
  static const double sustainedGlow = 0.38;

  /// Duração da queda do brilho (fração de t).
  static const double glowDecay = 0.18;

  /// Duração da expansão do glow emitido pela conexão (fração de t).
  static const double pulseSpan = 0.30;

  /// Posição do feixe no percurso (0..1). Velocidade constante; só pára
  /// no conector, durante o giro.
  double beamProgress(double t) {
    if (t <= approachStart) return 0;
    if (t < contact) return (t - approachStart) / moveSpan;
    if (t < connected) return entryAt;
    return _unit(entryAt + (t - connected) / moveSpan);
  }

  /// Giro do conector (0..1), do contato até a conexão.
  double spinTurns(double t) {
    if (t >= connected) return 1;
    final k = _unit((t - contact) / spinSpan);
    return Curves.easeInOutCubic.transform(k);
  }

  /// Quanto a barra interna já está conectada ao feixe (0..1).
  /// Acende no fim do giro, quando ela fica alinhada.
  double link(double t) {
    if (t >= connected) return 1;
    final k = _unit((t - (connected - glowSwell)) / glowSwell);
    return Curves.easeOut.transform(k);
  }

  /// Carga no ponto de contato durante o giro (0..1).
  double charge(double t) => _unit((t - contact) / spinSpan);

  /// Brilho do conector: sobe de leve durante o giro, estoura ao conectar,
  /// cai e permanece em [sustainedGlow].
  double glow(double t) {
    if (t <= contact) return 0;
    if (t < connected) {
      return chargeGlow * Curves.easeIn.transform(charge(t));
    }
    if (t < glowPeak) {
      final k = (t - connected) / glowSwell;
      return chargeGlow + (1.0 - chargeGlow) * Curves.easeOut.transform(k);
    }
    final k = _unit((t - glowPeak) / glowDecay);
    return 1.0 - (1.0 - sustainedGlow) * Curves.easeOutCubic.transform(k);
  }

  /// Expansão (0..1) do glow emitido no instante da conexão.
  double pulse(double t) {
    final k = _unit((t - connected) / pulseSpan);
    return Curves.easeOutCubic.transform(k);
  }

  /// Opacidade do nome: surge depois que o feixe deixa o conector e chega
  /// a 1 quando o feixe termina.
  double titleOpacity(double t) {
    final k = _unit((beamProgress(t) - exitAt) / (1.0 - exitAt));
    return Curves.easeOut.transform(k);
  }
}
