import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:synapse_core/synapse_core.dart';
import 'package:synapsezero/application/trail/trail_progress.dart';
import 'package:synapsezero/presentation/theme/app_colors.dart';
import 'package:synapsezero/presentation/trail/trail_node.dart';

/// Mapa em zigue-zague com os níveis de um setor (geometria do protótipo).
class TrailMap extends StatelessWidget {
  const TrailMap({
    super.key,
    required this.sectorIndex,
    required this.progress,
    required this.onLevelSelected,
  });

  /// Posição horizontal de cada nó, como fração da largura.
  static const List<double> nodeX = [0.50, 0.22, 0.50, 0.78, 0.50];

  /// Distância vertical entre nós, margem superior e altura do mapa.
  static const double step = 124;
  static const double top = 22;
  static const double height = levelsPerSector * step + 8;

  /// Distância do topo do nó ao centro do anel.
  static const double _ringCenter = 30;

  final int sectorIndex;
  final TrailProgress progress;
  final ValueChanged<int> onLevelSelected;

  @override
  Widget build(BuildContext context) {
    final first = sectorIndex * levelsPerSector;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoutePainter(
                    done: [
                      for (var k = 0; k < levelsPerSector - 1; k++)
                        progress.starsAt(first + k) > 0,
                    ],
                  ),
                ),
              ),
              for (var k = 0; k < levelsPerSector; k++)
                Positioned(
                  left: nodeX[k] * width - TrailNode.width / 2,
                  top: top + k * step,
                  child: TrailNode(
                    index: first + k,
                    name: levelNames[first + k],
                    state: progress.stateOf(first + k),
                    stars: progress.starsAt(first + k),
                    isBoss: k == levelsPerSector - 1,
                    onTap: () => onLevelSelected(first + k),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Rota tracejada entre os nós. Trechos já percorridos ficam em ciano, com brilho.
class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.done});

  /// `done[k]`: o nó k foi concluído, então o trecho k -> k+1 está aceso.
  final List<bool> done;

  static const double _dash = 9;
  static const double _gap = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final idle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.line;
    final lit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.alfa;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.alfaGlow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (var k = 0; k < done.length; k++) {
      final x1 = TrailMap.nodeX[k] * size.width;
      final x2 = TrailMap.nodeX[k + 1] * size.width;
      final y1 = TrailMap.top + k * TrailMap.step + TrailMap._ringCenter;
      final y2 = TrailMap.top + (k + 1) * TrailMap.step + TrailMap._ringCenter;
      final mid = (y1 + y2) / 2;
      final curve = Path()
        ..moveTo(x1, y1)
        ..cubicTo(x1, mid, x2, mid, x2, y2);
      final dashed = _dashed(curve);
      if (done[k]) {
        canvas.drawPath(dashed, glow);
        canvas.drawPath(dashed, lit);
      } else {
        canvas.drawPath(dashed, idle);
      }
    }
  }

  Path _dashed(Path source) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + _dash, metric.length);
        out.addPath(metric.extractPath(distance, end), Offset.zero);
        distance += _dash + _gap;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    if (oldDelegate.done.length != done.length) return true;
    for (var i = 0; i < done.length; i++) {
      if (oldDelegate.done[i] != done[i]) return true;
    }
    return false;
  }
}
