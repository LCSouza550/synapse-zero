import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import 'splash_timeline.dart';

/// Desenha o fundo quadriculado (28 px), igual ao da `.splash` do protótipo.
class SplashGridPainter extends CustomPainter {
  const SplashGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.bg);
    final line = Paint()
      ..color = AppColors.grid
      ..strokeWidth = 1;
    for (double x = 0.5; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0.5; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Desenha feixe, capacitor, halo e receptor em um único relógio ([clock]).
///
/// As coordenadas usam o mesmo `viewBox="0 0 320 80"` do SVG do protótipo; o
/// canvas é escalado para a largura disponível.
class SplashPainter extends CustomPainter {
  SplashPainter(this.clock) : super(repaint: clock);

  final Animation<double> clock;

  static const double _vbWidth = 320;
  static const double _vbHeight = 80;
  static const Offset _capCenter = Offset(156, 40);
  static const Offset _dstCenter = Offset(309, 40);

  /// Razão altura/largura do desenho.
  static const double aspect = _vbHeight / _vbWidth;

  // Traçado tracejado do anel médio (5 de traço, 3,5 de vão), calculado uma vez.
  static final Path _dashedRing = _buildDashedRing();

  static Path _buildDashedRing() {
    final source = Path()
      ..addOval(Rect.fromCircle(center: _capCenter, radius: 20));
    final out = Path();
    for (final metric in source.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        out.addPath(metric.extractPath(d, math.min(d + 5, metric.length)), Offset.zero);
        d += 8.5;
      }
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value * SplashTimeline.total;
    canvas.save();
    canvas.scale(size.width / _vbWidth);

    _paintWires(canvas);
    _paintSource(canvas);
    _paintBeam(canvas, 18, 129, SplashTimeline.beamAStart, SplashTimeline.beamADur, t);
    _paintBeam(canvas, 183, 297, SplashTimeline.beamBStart, SplashTimeline.beamBDur, t);
    _paintHalo(canvas, t);
    _paintCapacitor(canvas, t);
    _paintReceiver(canvas, t);
    _paintHead(canvas, 18, 129, SplashTimeline.beamAStart, SplashTimeline.beamADur, t);
    _paintHead(canvas, 183, 297, SplashTimeline.beamBStart, SplashTimeline.beamBDur, t);

    canvas.restore();
  }

  // ---------------------------------------------------------------- fios
  void _paintWires(Canvas canvas) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = AppColors.wireOff.withValues(alpha: 0.45);
    canvas.drawLine(const Offset(18, 40), const Offset(129, 40), p);
    canvas.drawLine(const Offset(183, 40), const Offset(297, 40), p);
  }

  void _paintSource(Canvas canvas) {
    const c = Offset(12, 40);
    canvas.drawCircle(
      c,
      6,
      Paint()
        ..color = AppColors.alfaGlow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(c, 6, Paint()..color = AppColors.alfa);
  }

  // --------------------------------------------------------------- feixe
  /// Feixe liso, em velocidade constante.
  void _paintBeam(Canvas canvas, double x0, double x1, double start, double dur, double t) {
    final p = SplashTimeline.seg(t, start, dur);
    if (p <= 0) return;
    final end = Offset(x0 + (x1 - x0) * p, 40);
    final start0 = Offset(x0, 40);
    canvas.drawLine(
      start0,
      end,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = AppColors.alfaGlow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawLine(
      start0,
      end,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = AppColors.alfa,
    );
  }

  /// Ponta luminosa que acompanha o feixe e some nos últimos 8% do trecho.
  void _paintHead(Canvas canvas, double x0, double x1, double start, double dur, double t) {
    if (t < start || t > start + dur) return;
    final p = SplashTimeline.seg(t, start, dur);
    final opacity = p < 0.92 ? 1.0 : 1.0 - (p - 0.92) / 0.08;
    final c = Offset(x0 + (x1 - x0) * p, 40);
    canvas.drawCircle(
      c,
      3.4,
      Paint()
        ..color = AppColors.alfaGlow.withValues(alpha: 0.55 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      c,
      3.4,
      Paint()
        ..color = AppColors.alfa.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(c, 3.4, Paint()..color = AppColors.flash.withValues(alpha: opacity));
  }

  // ---------------------------------------------------------------- halo
  /// Halo largo: dispara ao fim do giro, esmaece e permanece aceso até o fim.
  void _paintHalo(Canvas canvas, double t) {
    if (t < SplashTimeline.glowStart) return;
    final p = SplashTimeline.seg(t, SplashTimeline.glowStart, SplashTimeline.haloDur);
    double opacity;
    double scale;
    if (p < 0.08) {
      final u = SplashTimeline.easeOut.transform(p / 0.08);
      opacity = u;
      scale = 0.4 + (1.3 - 0.4) * u;
    } else {
      final u = SplashTimeline.easeOut.transform((p - 0.08) / 0.92);
      opacity = 1 + (0.55 - 1) * u;
      scale = 1.3 + (1.0 - 1.3) * u;
    }
    final radius = 115 * scale;
    const base = AppColors.alfa;
    final shader = ui.Gradient.radial(
      _capCenter,
      radius,
      [
        base.withValues(alpha: 0.9 * opacity),
        base.withValues(alpha: 0.5 * opacity),
        base.withValues(alpha: 0.17 * opacity),
        base.withValues(alpha: 0.0),
      ],
      const [0.0, 0.3, 0.65, 1.0],
    );
    canvas.drawCircle(_capCenter, radius, Paint()..shader = shader);
  }

  // ----------------------------------------------------------- capacitor
  void _paintCapacitor(Canvas canvas, double t) {
    final rotP = SplashTimeline.seg(t, SplashTimeline.rotStart, SplashTimeline.rotDur);
    final angle = (math.pi / 2) * (1 - SplashTimeline.rotCurve.transform(rotP));

    // Cor: desligado -> "acordado" (1,4 s) -> aceso (1,85 s), como `capwake`/`caplit`.
    final wake = Color.lerp(
      AppColors.wireOff,
      AppColors.wake,
      SplashTimeline.ease.transform(SplashTimeline.seg(t, SplashTimeline.rotStart, 0.15)),
    )!;
    final q = SplashTimeline.seg(t, SplashTimeline.glowStart, SplashTimeline.litDur);
    final color = t < SplashTimeline.glowStart
        ? wake
        : SplashTimeline.lit(AppColors.wake, q, AppColors.flash, AppColors.alfa);

    canvas.save();
    canvas.translate(_capCenter.dx, _capCenter.dy);
    canvas.rotate(angle);
    canvas.translate(-_capCenter.dx, -_capCenter.dy);

    // Brilho (equivale ao drop-shadow `capglow`): pico em 10% e repouso em 100%.
    if (t >= SplashTimeline.glowStart) {
      final g = SplashTimeline.seg(t, SplashTimeline.glowStart, SplashTimeline.capGlowDur);
      double outerSigma, outerAlpha, innerSigma;
      Color innerColor;
      double innerAlpha;
      if (g < 0.10) {
        final u = SplashTimeline.ease.transform(g / 0.10);
        outerSigma = 6 * u;
        outerAlpha = u;
        innerSigma = 1.5 * u;
        innerColor = AppColors.flash;
        innerAlpha = u;
      } else {
        final u = SplashTimeline.ease.transform((g - 0.10) / 0.90);
        outerSigma = 6 + (3.5 - 6) * u;
        outerAlpha = 1 + (0.6 - 1) * u;
        innerSigma = 1.5 + (1.0 - 1.5) * u;
        innerColor = Color.lerp(AppColors.flash, AppColors.alfa, u)!;
        innerAlpha = 1 + (0.7 - 1) * u;
      }
      if (outerSigma > 0.05) {
        _capShapes(canvas, AppColors.alfa.withValues(alpha: outerAlpha),
            blur: MaskFilter.blur(BlurStyle.normal, outerSigma), fills: false);
        _capShapes(canvas, innerColor.withValues(alpha: innerAlpha),
            blur: MaskFilter.blur(BlurStyle.normal, innerSigma), fills: false);
      }
    }

    _capShapes(canvas, color, fills: true);
    canvas.restore();
  }

  /// Anéis, marcas, terminais e condutor — tudo gira junto.
  void _capShapes(Canvas canvas, Color color, {MaskFilter? blur, required bool fills}) {
    Paint stroke(double width, {bool round = false}) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = round ? StrokeCap.round : StrokeCap.butt
      ..color = color
      ..maskFilter = blur;

    // Anel externo e anel tracejado
    canvas.drawCircle(_capCenter, 27, stroke(2.5));
    canvas.drawPath(_dashedRing, stroke(1.6));

    // Marcas a 30°, 60°, 120°, 150°, 210°, 240°, 300° e 330°
    final tick = stroke(1.6, round: true);
    for (final deg in const [30, 60, 120, 150, 210, 240, 300, 330]) {
      canvas.save();
      canvas.translate(_capCenter.dx, _capCenter.dy);
      canvas.rotate(deg * math.pi / 180);
      canvas.drawLine(const Offset(0, -33), const Offset(0, -29), tick);
      canvas.restore();
    }

    // Índice (triângulo no topo)
    final index = Path()
      ..moveTo(152, 4.5)
      ..lineTo(160, 4.5)
      ..lineTo(156, 11)
      ..close();
    canvas.drawPath(
      index,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color
        ..maskFilter = blur,
    );

    // Condutor, terminais e eixo central
    canvas.drawLine(const Offset(129, 40), const Offset(183, 40), stroke(3, round: true));
    for (final c in const [Offset(129, 40), Offset(183, 40)]) {
      if (fills) canvas.drawCircle(c, 3.4, Paint()..color = AppColors.bg);
      canvas.drawCircle(c, 3.4, stroke(2));
    }
    if (fills) canvas.drawCircle(_capCenter, 7, Paint()..color = AppColors.bg);
    canvas.drawCircle(_capCenter, 7, stroke(2));
  }

  // ------------------------------------------------------------ receptor
  void _paintReceiver(Canvas canvas, double t) {
    // Anel do receptor acende como o capacitor.
    final q = SplashTimeline.seg(t, SplashTimeline.dstStart, SplashTimeline.dstLitDur);
    final ring = t < SplashTimeline.dstStart
        ? AppColors.wireOff
        : SplashTimeline.lit(AppColors.wireOff, q, AppColors.flash, AppColors.alfa);
    canvas.drawCircle(
      _dstCenter,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = ring,
    );

    if (t < SplashTimeline.dstStart) return;

    // Núcleo: acende crescendo
    final ig = SplashTimeline.easeOut.transform(
        SplashTimeline.seg(t, SplashTimeline.dstStart, SplashTimeline.igniteDur));
    final coreRadius = 5 * (0.2 + 0.8 * ig);
    canvas.drawCircle(
      _dstCenter,
      coreRadius,
      Paint()
        ..color = AppColors.alfaGlow.withValues(alpha: 0.55 * ig)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(_dstCenter, coreRadius, Paint()..color = AppColors.alfa.withValues(alpha: ig));

    // Onda que se expande e some
    final pg = SplashTimeline.easeOut.transform(
        SplashTimeline.seg(t, SplashTimeline.dstStart, SplashTimeline.pingDur));
    final scale = 1 + 1.6 * pg;
    canvas.drawCircle(
      _dstCenter,
      10 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale
        ..color = AppColors.alfa.withValues(alpha: 0.7 * (1 - pg)),
    );
  }

  @override
  bool shouldRepaint(covariant SplashPainter oldDelegate) => oldDelegate.clock != clock;
}
