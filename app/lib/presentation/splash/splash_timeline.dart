
import 'package:flutter/animation.dart';

/// Linha do tempo da splash, em segundos. Os valores são os do protótipo HTML
/// (CSS da `.splash` e `Snd.splash`), para o visual e o som continuarem idênticos.
abstract final class SplashTimeline {
  /// Duração total até abrir a tela principal (o protótipo usava 4100 ms).
  static const double total = 4.1;

  // Feixe e capacitor
  static const double beamAStart = 0.2;
  static const double beamADur = 1.2;
  static const double rotStart = 1.4;
  static const double rotDur = 0.45;
  static const double beamBStart = 1.85;
  static const double beamBDur = 1.25;

  // Brilho do capacitor, halo e nome (disparam ao fim do giro)
  static const double glowStart = 1.85;
  static const double haloDur = 2.0;
  static const double capGlowDur = 1.6;
  static const double litDur = 1.3;
  static const double titleDur = 1.25;

  // Receptor
  static const double dstStart = 3.1;
  static const double dstLitDur = 0.6;
  static const double igniteDur = 0.45;
  static const double pingDur = 0.9;

  // Curvas CSS usadas no protótipo
  static const Curve rotCurve = Cubic(0.5, 0.0, 0.2, 1.0);
  static const Curve titleCurve = Cubic(0.3, 0.0, 0.4, 1.0);
  static const Curve ease = Curves.ease;
  static const Curve easeOut = Curves.easeOut;

  /// Progresso 0..1 de uma animação que começa em [start] e dura [dur].
  static double seg(double t, double start, double dur) =>
      ((t - start) / dur).clamp(0.0, 1.0).toDouble();

  /// Cor de "ligar": de [from] até branco-azulado a 12% e depois até ciano
  /// (keyframes `caplit` do protótipo).
  static Color lit(Color from, double q, Color flash, Color alfa) {
    if (q <= 0) return from;
    if (q < 0.12) {
      return Color.lerp(from, flash, ease.transform(q / 0.12))!;
    }
    return Color.lerp(flash, alfa, ease.transform((q - 0.12) / 0.88))!;
  }
}
