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

/// Geometria da splash. As frações vêm de [SplashTimeline], a fonte única.
class _Geometry {
  _Geometry(Size size)
      : startX = size.width * SplashTimeline.startFrac,
        endX = size.width * SplashTimeline.endFrac,
        centerX = size.width * SplashTimeline.centerFrac,
        y = size.height / 2,
        radius = size.width * SplashTimeline.radiusFrac;

  final double startX;
  final double endX;

  /// O conector fica no centro exato da tela (horizontal e vertical).
  final double centerX;
  final double y;
  final double radius;
}

/// Desenha feixe, glow e conector. Repinta a cada frame do controller.
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
    ..strokeWidth = 16
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

  final Paint _beamMid = Paint()
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;

  final Paint _beamCore = Paint()
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;

  final Paint _headGlow = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  final Paint _headCore = Paint();

  final Paint _haloFill = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final g = _Geometry(size);

    canvas.drawLine(Offset(g.startX, g.y), Offset(g.endX, g.y), _track);

    // Glow e conector ficam sob o feixe, que passa por dentro da barra
    // interna depois que ela se alinha.
    _paintGlow(canvas, g, t);
    _paintConnector(canvas, g, t);

    final progress = timeline.beamProgress(t);
    if (progress <= 0) return;

    // Antes da conexão o feixe pára no contato (progress == entryAt),
    // portanto nunca entra no conector fechado.
    final start = Offset(g.startX, g.y);
    final head = Offset(g.startX + (g.endX - g.startX) * progress, g.y);
    _drawBeam(canvas, start, head);

    // Durante o giro a cabeça cresce no ponto de contato (carga) e volta
    // ao tamanho normal quando a conexão fecha.
    final scale = 1 + 0.8 * timeline.charge(t) * (1 - timeline.link(t));
    _drawHead(canvas, head, scale: scale);
  }

  void _drawBeam(Canvas canvas, Offset from, Offset to) {
    _beamGlow.color = SynapsePalette.cyan.withValues(alpha: 0.55);
    _beamMid.color = SynapsePalette.cyan;
    _beamCore.color = SynapsePalette.cyanCore;
    canvas.drawLine(from, to, _beamGlow);
    canvas.drawLine(from, to, _beamMid);
    canvas.drawLine(from, to, _beamCore);
  }

  void _drawHead(Canvas canvas, Offset head, {double scale = 1}) {
    _headGlow.color = SynapsePalette.cyan.withValues(alpha: 0.8);
    _headCore.color = SynapsePalette.cyanCore;
    canvas.drawCircle(head, 14 * scale, _headGlow);
    canvas.drawCircle(head, 4.5 * scale, _headCore);
  }

  /// Glow emitido pelo conector: um brilho permanente que acompanha
  /// [SplashTimeline.glow] e um pulso suave que se expande no instante
  /// da conexão (sem contornos duros).
  void _paintGlow(Canvas canvas, _Geometry g, double t) {
    final center = Offset(g.centerX, g.y);
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

    final k = timeline.pulse(t);
    if (k > 0 && k < 1) {
      final radius = g.radius * (1.2 + 3.2 * k);
      _haloFill.shader = RadialGradient(
        colors: [
          SynapsePalette.amberCore.withValues(alpha: 0),
          SynapsePalette.amber.withValues(alpha: 0.6 * (1 - k)),
          SynapsePalette.amber.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, _haloFill);
    }
  }

  void _paintConnector(Canvas canvas, _Geometry g, double t) {
    final glow = timeline.glow(t);
    // Inclina 1/4 de volta: parte com a barra na vertical (sem passagem) e
    // termina com ela na horizontal, alinhada ao feixe.
    final angle = -math.pi / 2 + timeline.spinTurns(t) * math.pi / 2;
    final link = timeline.link(t);
    final crisp = Color.lerp(
      SynapsePalette.capacitorIdle,
      SynapsePalette.amberCore,
      glow,
    )!;
    final bar = Color.lerp(
      SynapsePalette.capacitorIdle,
      SynapsePalette.cyanCore,
      link,
    )!;

    canvas.save();
    canvas.translate(g.centerX, g.y);
    // Gira o conjunto inteiro (anéis, barra de conexão e núcleo).
    canvas.rotate(angle);
    if (glow > 0.01) {
      final glowColor = SynapsePalette.amber.withValues(alpha: 0.9 * glow);
      _drawConnectorParts(
        canvas,
        g.radius,
        color: glowColor,
        barColor: glowColor,
        widthScale: 2.2,
        blur: 14,
      );
    }
    _drawConnectorParts(
      canvas,
      g.radius,
      color: crisp,
      barColor: bar,
      widthScale: 1,
    );
    canvas.restore();
  }

  void _drawConnectorParts(
    Canvas canvas,
    double radius, {
    required Color color,
    required Color barColor,
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

    // Anel externo: duas metades, com aberturas em 0 e π. Com o conector
    // alinhado, as aberturas ficam na direção do feixe.
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

    // Marca de referência: torna o giro visível.
    paint.strokeWidth = 4 * widthScale;
    canvas.drawLine(
      Offset.fromDirection(-math.pi / 2, radius * 0.78),
      Offset.fromDirection(-math.pi / 2, radius * 1.18),
      paint,
    );

    // Barra de conexão: ao alinhar com o feixe, liga a abertura da esquerda
    // à da direita e permite a passagem.
    final barPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5 * widthScale
      ..color = barColor;
    if (blur > 0) {
      barPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    }
    canvas.drawLine(Offset(-radius, 0), Offset(radius, 0), barPaint);

    // Núcleo.
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 0.16, paint);
  }

  @override
  bool shouldRepaint(covariant SplashPainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.timeline != timeline;
}
