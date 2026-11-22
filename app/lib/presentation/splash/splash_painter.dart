import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/presentation/splash/splash_timeline.dart';
import 'package:synapsezero/presentation/theme/synapse_palette.dart';

/// Grade de fundo. Estática: desenhada uma vez, isolada em RepaintBoundary.
class GridPainter extends CustomPainter {
  const GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SynapsePalette.gridLine
      ..strokeWidth = 1;
    const step = 32.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => false;
}

class _Geometry {
  _Geometry(Size size)
      : startX = size.width * 0.08,
        endX = size.width * 0.92,
        y = size.height * 0.46,
        radius = size.width * 0.13,
        capX = size.width * (0.08 + 0.84 * SplashTimeline.capacitorAt);

  final double startX;
  final double endX;
  final double y;
  final double radius;
  final double capX;
}

/// Desenha feixe, halo e capacitor. Repinta a cada frame do controller.
class SplashPainter extends CustomPainter {
  SplashPainter({required this.animation, required this.timeline})
      : super(repaint: animation);

  final Animation<double> animation;
  final SplashTimeline timeline;

  final Paint _track = Paint()
    ..color = SynapsePalette.cyan.withValues(alpha: 0.14)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  final Paint _beamGlow = Paint()
    ..color = SynapsePalette.cyan.withValues(alpha: 0.55)
    ..strokeWidth = 16
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

  final Paint _beamMid = Paint()
    ..color = SynapsePalette.cyan
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;

  final Paint _beamCore = Paint()
    ..color = SynapsePalette.cyanCore
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;

  final Paint _headGlow = Paint()
    ..color = SynapsePalette.cyan.withValues(alpha: 0.8)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  final Paint _headCore = Paint()..color = SynapsePalette.cyanCore;

  final Paint _haloFill = Paint();

  final Paint _haloRing = Paint()
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final geometry = _Geometry(size);

    _paintTrack(canvas, geometry);
    _paintBeam(canvas, geometry, timeline.beamProgress(t));
    _paintHalo(canvas, geometry, t);
    _paintCapacitor(canvas, geometry, t);
  }

  void _paintTrack(Canvas canvas, _Geometry g) {
    canvas.drawLine(Offset(g.startX, g.y), Offset(g.endX, g.y), _track);
  }

  void _paintBeam(Canvas canvas, _Geometry g, double progress) {
    if (progress <= 0) return;
    final start = Offset(g.startX, g.y);
    final head = Offset(g.startX + (g.endX - g.startX) * progress, g.y);

    canvas.drawLine(start, head, _beamGlow);
    canvas.drawLine(start, head, _beamMid);
    canvas.drawLine(start, head, _beamCore);
    canvas.drawCircle(head, 14, _headGlow);
    canvas.drawCircle(head, 4.5, _headCore);
  }

  void _paintHalo(Canvas canvas, _Geometry g, double t) {
    final center = Offset(g.capX, g.y);
    final glow = timeline.glow(t);

    if (glow > 0) {
      final radius = g.radius * 2.6;
      _haloFill.shader = RadialGradient(
        colors: [
          SynapsePalette.amber.withValues(alpha: 0.55 * glow),
          SynapsePalette.amber.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, _haloFill);
    }

    for (final delay in SplashTimeline.haloDelays) {
      final k = timeline.haloProgress(t, delay: delay);
      if (k <= 0 || k >= 1) continue;
      _haloRing
        ..color = SynapsePalette.amber.withValues(alpha: 0.8 * (1 - k))
        ..strokeWidth = 3 + 6 * (1 - k);
      canvas.drawCircle(center, g.radius * (1.1 + 2.6 * k), _haloRing);
    }
  }

  void _paintCapacitor(Canvas canvas, _Geometry g, double t) {
    final glow = timeline.glow(t);
    final angle = timeline.spinTurns(t) * 2 * math.pi;
    final crisp = Color.lerp(
      SynapsePalette.capacitorIdle,
      SynapsePalette.amberCore,
      glow,
    )!;

    canvas.save();
    canvas.translate(g.capX, g.y);
    // Gira o conjunto inteiro (anéis externos, internos e núcleo).
    canvas.rotate(angle);
    if (glow > 0.01) {
      _drawRings(
        canvas,
        g.radius,
        color: SynapsePalette.amber.withValues(alpha: 0.9 * glow),
        widthScale: 2.2,
        blur: 14,
      );
    }
    _drawRings(canvas, g.radius, color: crisp, widthScale: 1);
    canvas.restore();
  }

  void _drawRings(
    Canvas canvas,
    double radius, {
    required Color color,
    required double widthScale,
    double blur = 0,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    if (blur > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    }

    // Anel externo: duas metades, com aberturas alinhadas ao feixe (0 e π).
    paint.strokeWidth = 6 * widthScale;
    final outer = Rect.fromCircle(center: Offset.zero, radius: radius);
    const gap = 0.55;
    canvas.drawArc(outer, gap / 2, math.pi - gap, false, paint);
    canvas.drawArc(outer, math.pi + gap / 2, math.pi - gap, false, paint);

    // Anel interno com marcas diagonais.
    paint.strokeWidth = 2.5 * widthScale;
    canvas.drawCircle(Offset.zero, radius * 0.66, paint);
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      canvas.drawLine(
        Offset.fromDirection(a, radius * 0.66),
        Offset.fromDirection(a, radius * 0.84),
        paint,
      );
    }

    // Marca de referência no topo: torna a volta completa visível.
    paint.strokeWidth = 4 * widthScale;
    canvas.drawLine(
      Offset.fromDirection(-math.pi / 2, radius * 0.78),
      Offset.fromDirection(-math.pi / 2, radius * 1.18),
      paint,
    );

    // Núcleo.
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 0.16, paint);
  }

  @override
  bool shouldRepaint(covariant SplashPainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.timeline != timeline;
}