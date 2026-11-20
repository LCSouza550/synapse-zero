import 'dart:typed_data';

import 'constants.dart';
import 'grid.dart';
import 'models.dart';

/// Propaga a energia de cada rede a partir da borda esquerda e informa quais
/// células acendem e quais redes chegaram à saída (borda direita).
Evaluation evaluateBoard({
  required int n,
  required List<Tile> tiles,
  required List<NetInfo> nets,
  required List<int> rots,
}) {
  final size = n * n;
  final cm = List<int>.generate(size, (i) => tiles[i].mask != 0 ? rotMask(tiles[i].mask, rots[i]) : 0);
  final lit = List<int>.filled(size, -1);
  final netSolved = <bool>[];
  final fed = <bool>[];

  for (var k = 0; k < nets.length; k++) {
    final net = nets[k];
    final seen = Uint8List(size);
    final stack = <int>[];
    final connected = (cm[net.src] & bit[west]) != 0;
    if (connected) {
      seen[net.src] = 1;
      stack.add(net.src);
    }
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      if (lit[i] < 0) lit[i] = k;
      final r = i ~/ n;
      final c = i % n;
      for (var d = 0; d < 4; d++) {
        if ((cm[i] & bit[d]) == 0) continue;
        final nr = r + dr[d];
        final nc = c + dc[d];
        if (nr < 0 || nc < 0 || nr >= n || nc >= n) continue;
        final j = nr * n + nc;
        if (seen[j] == 1) continue;
        if ((cm[j] & bit[(d + 2) % 4]) != 0) {
          seen[j] = 1;
          stack.add(j);
        }
      }
    }
    fed.add(connected);
    netSolved.add(seen[net.dst] == 1 && (cm[net.dst] & bit[east]) != 0);
  }

  var litCount = 0;
  for (final v in lit) {
    if (v >= 0) litCount++;
  }
  return Evaluation(lit: lit, netSolved: netSolved, fed: fed, litCount: litCount);
}

extension LevelEvaluation on Level {
  /// Avalia o tabuleiro com as rotações [rots] (uma por célula).
  Evaluation evaluate(List<int> rots) => evaluateBoard(n: n, tiles: tiles, nets: nets, rots: rots);
}
