import 'dart:math' as math;
import 'dart:typed_data';

import 'constants.dart';
import 'evaluator.dart';
import 'grid.dart';
import 'models.dart';
import 'rng.dart';

/// Gera um circuito por Reverse-Path Backtracking: o caminho resolvido é
/// construído primeiro (busca em profundidade com retrocesso) e só depois
/// os conduítes são embaralhados. Por construção, todo circuito tem solução.
///
/// A mesma [LevelSpec] (em especial a mesma semente) sempre gera o mesmo
/// circuito.
Level generateLevel(LevelSpec spec) {
  final n = spec.size;
  final nets = spec.nets;
  final rnd = Mulberry32(spec.seed);
  final cells = n * n;
  final maxLen = (cells * (nets == 1 ? 0.6 : 0.36)).floor();
  final minLen = math.min(maxLen - 1, (n * (1.2 + (nets == 1 ? 1.0 : 0.55) * spec.winding)).ceil());

  List<List<int>>? found;
  var fallback = false;
  for (var attempt = 0; attempt < 80 && found == null; attempt++) {
    final ends = _pickEndpoints(n, nets, rnd);
    final occupied = Uint8List(cells);
    for (var k = 1; k < nets; k++) {
      occupied[ends[k].s] = 1;
      occupied[ends[k].t] = 1;
    }
    final p0 = _carvePath(n, occupied, rnd, ends[0].s, ends[0].t, minLen, maxLen, 4000);
    if (p0 == null) continue;
    final candidate = <List<int>>[p0];
    if (nets == 2) {
      final occupied2 = Uint8List(cells);
      for (final i in p0) {
        occupied2[i] = 1;
      }
      final p1 = _carvePath(n, occupied2, rnd, ends[1].s, ends[1].t, minLen, maxLen, 4000);
      if (p1 == null) continue;
      candidate.add(p1);
    }
    found = candidate;
  }
  if (found == null) {
    fallback = true;
  }
  final paths = found ?? (nets == 1 ? [_rowPath(n, 0)] : [_rowPath(n, 0), _rowPath(n, n - 1)]);

  final tiles = List<Tile?>.filled(cells, null);
  final netInfo = <NetInfo>[];
  for (var k = 0; k < paths.length; k++) {
    final p = paths[k];
    for (var q = 0; q < p.length; q++) {
      final c = p[q];
      final pd = q == 0 ? west : dirBetween(n, c, p[q - 1]);
      final nd = q == p.length - 1 ? east : dirBetween(n, c, p[q + 1]);
      final m = bit[pd] | bit[nd];
      final base = (m == 5 || m == 10) ? TileKind.straight : TileKind.elbow;
      final solved = <int>[
        for (var r = 0; r < 4; r++)
          if (rotMask(base, r) == m) r,
      ];
      tiles[c] = Tile(role: TileRole.path, net: k, pos: q, mask: base, rot: 0, solved: solved);
    }
    netInfo.add(NetInfo(
      src: p.first,
      dst: p.last,
      inRow: p.first ~/ n,
      outRow: p.last ~/ n,
      path: List<int>.of(p),
    ));
  }

  for (var i = 0; i < cells; i++) {
    if (tiles[i] != null) continue;
    final y = rnd.next();
    final mask = y < 0.36
        ? TileKind.elbow
        : y < 0.66
            ? TileKind.straight
            : y < 0.9
                ? TileKind.tee
                : TileKind.cross;
    tiles[i] = Tile(role: TileRole.decoy, net: -1, pos: -1, mask: mask, rot: (rnd.next() * 4).floor());
  }
  final board = <Tile>[for (final t in tiles) t!];

  // Bônus ⚡+2: ficam em conduítes do circuito, perto da entrada.
  final bonus = <int>[];
  final bonusCount = math.min(spec.bonus, nets);
  for (var k = 0; k < bonusCount; k++) {
    final p = paths[k];
    final pos = math.max(2, math.min(p.length - 3, (p.length * (k == 0 ? 0.4 : 0.55)).floor()));
    bonus.add(p[pos]);
  }

  final pathIdx = <int>[
    for (var i = 0; i < cells; i++)
      if (board[i].role == TileRole.path) i,
  ];
  final rots = <int>[for (final t in board) t.rot];

  double wrongFraction() {
    var wrong = 0;
    for (final i in pathIdx) {
      if (!board[i].solved!.contains(rots[i])) wrong++;
    }
    return wrong / pathIdx.length;
  }

  void scramble() {
    for (final i in pathIdx) {
      final solved = board[i].solved!;
      final wrong = <int>[
        for (var r = 0; r < 4; r++)
          if (!solved.contains(r)) r,
      ];
      rots[i] = rnd.next() < 0.88 ? wrong[(rnd.next() * wrong.length).floor()] : (rnd.next() * 4).floor();
    }
  }

  var tries = 0;
  do {
    scramble();
    tries++;
    final ev = evaluateBoard(n: n, tiles: board, nets: netInfo, rots: rots);
    if (!ev.netSolved.any((s) => s) && wrongFraction() >= 0.5) break;
  } while (tries < 40);

  final finalTiles = <Tile>[for (var i = 0; i < cells; i++) board[i].withRot(rots[i])];

  var optCW = 0;
  var optBoth = 0;
  for (final i in pathIdx) {
    final t = finalTiles[i];
    var cw = 4;
    var ccw = 4;
    for (final r in t.solved!) {
      cw = math.min(cw, (r - t.rot + 4) % 4);
      ccw = math.min(ccw, (t.rot - r + 4) % 4);
    }
    optCW += cw;
    optBoth += math.min(cw, ccw);
  }
  final slack = math.max(2, (optCW * spec.slack).ceil());

  return Level(
    n: n,
    tiles: finalTiles,
    nets: netInfo,
    bonus: bonus,
    seed: spec.seed & 0xFFFFFFFF,
    fallback: fallback,
    meta: LevelMeta(name: spec.name, complexity: spec.complexity, boss: spec.boss),
    optCW: optCW,
    optBoth: optBoth,
    slack: slack,
    budget: optCW + slack,
    pathTiles: pathIdx.length,
  );
}

List<int> _shuffle(List<int> items, Mulberry32 rnd) {
  for (var i = items.length - 1; i > 0; i--) {
    final j = (rnd.next() * (i + 1)).floor();
    final tmp = items[i];
    items[i] = items[j];
    items[j] = tmp;
  }
  return items;
}

List<int> _rowPath(int n, int row) => <int>[for (var c = 0; c < n; c++) row * n + c];

/// Busca em profundidade com retrocesso: caminho simples de [s] a [t] com
/// comprimento entre [minLen] e [maxLen], evitando células em [occupied].
List<int>? _carvePath(
  int n,
  Uint8List occupied,
  Mulberry32 rnd,
  int s,
  int t,
  int minLen,
  int maxLen,
  int nodeCap,
) {
  final used = Uint8List(n * n);
  final path = <int>[s];
  used[s] = 1;
  var nodes = 0;
  final tr = t ~/ n;
  final tc = t % n;

  bool dfs(int cur) {
    if (cur == t) return path.length >= minLen;
    if (++nodes > nodeCap) return false;
    final r = cur ~/ n;
    final c = cur % n;
    final order = _shuffle([0, 1, 2, 3], rnd);
    for (var k = 0; k < 4; k++) {
      final d = order[k];
      final nr = r + dr[d];
      final nc = c + dc[d];
      if (nr < 0 || nc < 0 || nr >= n || nc >= n) continue;
      final j = nr * n + nc;
      if (used[j] == 1 || occupied[j] == 1) continue;
      final rem = (nr - tr).abs() + (nc - tc).abs();
      if (path.length + 1 + rem > maxLen) continue;
      used[j] = 1;
      path.add(j);
      if (dfs(j)) return true;
      path.removeLast();
      used[j] = 0;
      if (nodes > nodeCap) return false;
    }
    return false;
  }

  return dfs(s) ? List<int>.of(path) : null;
}

/// Portas: sempre da coluna esquerda para a direita. Com duas redes, as
/// linhas de entrada e saída seguem a mesma ordem nas duas bordas, o que
/// permite traçar caminhos disjuntos.
List<({int s, int t})> _pickEndpoints(int n, int nets, Mulberry32 rnd) {
  int row() => (rnd.next() * n).floor();
  for (var tries = 0; tries < 200; tries++) {
    final a = row();
    final b = row();
    if (nets == 1) return [(s: a * n, t: b * n + n - 1)];
    final options = <String>[];
    if (a >= 1 && b >= 1) options.add('up');
    if (a <= n - 2 && b <= n - 2) options.add('down');
    if (options.isEmpty) continue;
    final side = options[(rnd.next() * options.length).floor()];
    final int c;
    final int d;
    if (side == 'up') {
      c = (rnd.next() * a).floor();
      d = (rnd.next() * b).floor();
    } else {
      c = a + 1 + (rnd.next() * (n - 1 - a)).floor();
      d = b + 1 + (rnd.next() * (n - 1 - b)).floor();
    }
    return [(s: a * n, t: b * n + n - 1), (s: c * n, t: d * n + n - 1)];
  }
  return [(s: 0, t: n - 1), (s: (n - 1) * n, t: n * n - 1)];
}
