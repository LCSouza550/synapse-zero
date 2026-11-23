import 'dart:math' as math;

import 'constants.dart';
import 'models.dart';
import 'rng.dart';

/// Quantidade de níveis da Trilha Neural (12 setores de [levelsPerSector]).
const int trailLength = 60;

/// Níveis do protótipo original. Seus parâmetros não mudam: os vetores de
/// referência (`test/golden`) dependem deles.
const int _prototypeLevels = 20;

/// Especificação do nível [index] (0 a [trailLength] - 1) da Trilha Neural.
///
/// - Níveis 0 a 19 (setores 1 a 4): idênticos ao protótipo.
/// - Níveis 20 a 59 (setores 5 a 12): repetem o formato do setor equivalente
///   (`sectorIndex % 4`), com sinuosidade maior a cada ciclo e folga mínima.
LevelSpec trailSpec(int index) {
  assert(index >= 0 && index < trailLength, 'índice de nível fora da trilha');
  final sectorIndex = index ~/ levelsPerSector;
  final sector = sectors[sectorIndex];
  final within = index % levelsPerSector;
  final cycle = sectorIndex ~/ 4;
  return LevelSpec(
    size: sector.size,
    nets: sector.nets,
    winding: math.min(0.85, 0.15 + 0.17 * within + 0.12 * cycle),
    slack: index < _prototypeLevels ? 0.5 - 0.38 * (index / 19) : 0.1,
    seed: 9000 + index * 101,
    bonus: index == 0
        ? 0
        : index >= 10
            ? 2
            : 1,
    complexity: _trailComplexity(sectorIndex),
    name: levelNames[index],
    boss: within == levelsPerSector - 1,
  );
}

/// Complexidade exibida: setores 1 a 4 como no protótipo; a partir do
/// setor 5, "Alta" (formatos 5x5, 6x6 e 7x7) ou "Extrema" (8x8).
String _trailComplexity(int sectorIndex) {
  if (sectorIndex < 4) return complexityNames[sectorIndex];
  return complexityNames[sectorIndex % 4 == 3 ? 3 : 2];
}

/// Especificação da etapa [stage] (0 a 2) do Desafio Diário de [day]
/// (formato AAAA-MM-DD). A semente é derivada da data: todos os jogadores
/// recebem os mesmos circuitos no mesmo dia.
LevelSpec dailySpec(String day, int stage) {
  final d = dailyStages[stage];
  return LevelSpec(
    size: d.size,
    nets: d.nets,
    winding: d.winding,
    slack: d.slack,
    bonus: d.bonus,
    seed: hashString('$day:$stage'),
    complexity: complexityNames[d.level],
    name: 'Etapa ${stage + 1}',
  );
}

ArenaDifficulty arenaDifficulty(String key) => arenaDifficulties.firstWhere((x) => x.key == key);

/// Especificação do Modo Arena para a dificuldade [key] e a [seed] dada.
LevelSpec arenaSpec(String key, int seed) {
  final d = arenaDifficulty(key);
  return LevelSpec(
    size: d.size,
    nets: d.nets,
    winding: d.winding,
    slack: d.slack,
    bonus: d.bonus,
    seed: seed & 0xFFFFFFFF,
    complexity: complexityNames[d.level],
    name: d.name,
  );
}
