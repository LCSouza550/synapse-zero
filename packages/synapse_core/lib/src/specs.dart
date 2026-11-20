import 'constants.dart';
import 'models.dart';
import 'rng.dart';

/// Quantidade de níveis da Trilha Neural.
const int trailLength = 20;

/// Especificação do nível [index] (0 a 19) da Trilha Neural.
LevelSpec trailSpec(int index) {
  assert(index >= 0 && index < trailLength, 'índice de nível fora da trilha');
  final sectorIndex = index ~/ 5;
  final sector = sectors[sectorIndex];
  final within = index % 5;
  return LevelSpec(
    size: sector.size,
    nets: sector.nets,
    winding: 0.15 + 0.17 * within,
    slack: 0.5 - 0.38 * (index / 19),
    seed: 9000 + index * 101,
    bonus: index == 0
        ? 0
        : index >= 10
            ? 2
            : 1,
    complexity: complexityNames[sectorIndex],
    name: levelNames[index],
    boss: within == 4,
  );
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
