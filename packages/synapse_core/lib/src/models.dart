/// Papel de um conduíte no circuito.
enum TileRole {
  /// Faz parte do caminho resolvido de uma rede.
  path,

  /// Isca: preenche o tabuleiro e não pertence a nenhuma solução.
  decoy,
}

/// Conduíte de uma célula do tabuleiro.
class Tile {
  const Tile({
    required this.role,
    required this.net,
    required this.pos,
    required this.mask,
    required this.rot,
    this.solved,
  });

  final TileRole role;

  /// Índice da rede (0 = Alfa, 1 = Beta), ou -1 para iscas.
  final int net;

  /// Posição ao longo do caminho da rede, ou -1 para iscas.
  final int pos;

  /// Máscara de conexões na rotação 0.
  final int mask;

  /// Rotação inicial (quartos de volta, sentido horário), já embaralhada.
  final int rot;

  /// Rotações que resolvem a célula (apenas em conduítes do caminho).
  final List<int>? solved;

  Tile withRot(int newRot) => Tile(role: role, net: net, pos: pos, mask: mask, rot: newRot, solved: solved);
}

/// Entrada, saída e caminho resolvido de uma rede.
class NetInfo {
  const NetInfo({
    required this.src,
    required this.dst,
    required this.inRow,
    required this.outRow,
    required this.path,
  });

  final int src;
  final int dst;
  final int inRow;
  final int outRow;
  final List<int> path;
}

class LevelMeta {
  const LevelMeta({required this.name, required this.complexity, required this.boss});

  final String name;
  final String complexity;
  final bool boss;
}

/// Parâmetros de geração de um circuito.
class LevelSpec {
  const LevelSpec({
    required this.size,
    required this.seed,
    this.nets = 1,
    this.winding = 0.5,
    this.slack = 0.3,
    this.bonus = 0,
    this.name = '',
    this.complexity = '',
    this.boss = false,
  });

  final int size;
  final int seed;
  final int nets;
  final double winding;
  final double slack;
  final int bonus;
  final String name;
  final String complexity;
  final bool boss;
}

/// Circuito gerado, com solvabilidade garantida.
class Level {
  const Level({
    required this.n,
    required this.tiles,
    required this.nets,
    required this.bonus,
    required this.seed,
    required this.fallback,
    required this.meta,
    required this.optCW,
    required this.optBoth,
    required this.slack,
    required this.budget,
    required this.pathTiles,
  });

  final int n;
  final List<Tile> tiles;
  final List<NetInfo> nets;

  /// Células com bônus ⚡+2 (devolvem 2 cliques ao serem energizadas).
  final List<int> bonus;
  final int seed;

  /// Verdadeiro se o gerador recorreu ao caminho reto de emergência.
  final bool fallback;
  final LevelMeta meta;

  /// Mínimo de cliques, girando apenas no sentido horário.
  final int optCW;

  /// Mínimo de cliques, podendo girar nos dois sentidos.
  final int optBoth;

  /// Folga de cliques acima do ótimo.
  final int slack;

  /// Cliques iniciais (ótimo + folga).
  final int budget;
  final int pathTiles;

  List<int> get initialRots => [for (final t in tiles) t.rot];
}

/// Resultado da propagação de energia pelo tabuleiro.
class Evaluation {
  const Evaluation({
    required this.lit,
    required this.netSolved,
    required this.fed,
    required this.litCount,
  });

  /// Para cada célula, a rede que a energiza (0, 1) ou -1 se apagada.
  final List<int> lit;

  /// Para cada rede, se a saída foi alcançada.
  final List<bool> netSolved;

  /// Para cada rede, se a entrada está conectada à primeira célula.
  final List<bool> fed;
  final int litCount;

  bool get solved => netSolved.every((s) => s);
}
