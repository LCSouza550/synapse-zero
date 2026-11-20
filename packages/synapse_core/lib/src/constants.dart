/// Direções: 0 = N, 1 = E, 2 = S, 3 = W.
const int north = 0;
const int east = 1;
const int south = 2;
const int west = 3;

/// Deslocamento de linha e coluna para cada direção.
const List<int> dr = [-1, 0, 1, 0];
const List<int> dc = [0, 1, 0, -1];

/// Máscara de conexões: N = 1, E = 2, S = 4, W = 8.
const List<int> bit = [1, 2, 4, 8];

/// Formatos de conduíte, expressos pela máscara na rotação 0.
abstract final class TileKind {
  static const int elbow = 3;
  static const int straight = 5;
  static const int tee = 7;
  static const int cross = 15;
}

/// Setor da Trilha Neural (5 níveis cada).
class Sector {
  const Sector(this.id, this.name, this.size, this.nets);

  final String id;
  final String name;
  final int size;
  final int nets;
}

const List<Sector> sectors = [
  Sector('cortex', 'Córtex Primário', 5, 1),
  Sector('ponte', 'Ponte Sináptica', 6, 1),
  Sector('nucleo', 'Núcleo Quântico', 7, 2),
  Sector('singularidade', 'Singularidade', 8, 2),
];

const List<String> levelNames = [
  'Primeiro Pulso', 'Sinapse Linear', 'Desvio Duplo', 'Nó Capacitor', 'Guardião Alfa',
  'Ponte Inicial', 'Axônio Curto', 'Fenda Sináptica', 'Eco Dendrítico', 'Guardião Beta',
  'Duas Frequências', 'Spin Cruzado', 'Emaranhado', 'Colapso de Onda', 'Guardião Gama',
  'Horizonte', 'Lente Gravitacional', 'Órbita Instável', 'Ponto de Não Retorno', 'Guardião Zero',
];

const List<String> complexityNames = ['Baixa', 'Média', 'Alta', 'Extrema'];

/// Dificuldade do Modo Arena.
class ArenaDifficulty {
  const ArenaDifficulty({
    required this.key,
    required this.name,
    required this.size,
    required this.nets,
    required this.winding,
    required this.slack,
    required this.bonus,
    required this.level,
  });

  final String key;
  final String name;
  final int size;
  final int nets;
  final double winding;
  final double slack;
  final int bonus;

  /// Índice em [complexityNames].
  final int level;
}

const List<ArenaDifficulty> arenaDifficulties = [
  ArenaDifficulty(key: 'facil', name: 'Fácil', size: 5, nets: 1, winding: 0.3, slack: 0.45, bonus: 0, level: 0),
  ArenaDifficulty(key: 'medio', name: 'Médio', size: 6, nets: 1, winding: 0.6, slack: 0.32, bonus: 1, level: 1),
  ArenaDifficulty(key: 'dificil', name: 'Difícil', size: 7, nets: 2, winding: 0.5, slack: 0.22, bonus: 2, level: 2),
  ArenaDifficulty(key: 'extremo', name: 'Extremo', size: 8, nets: 2, winding: 0.7, slack: 0.14, bonus: 2, level: 3),
];

/// Etapa do Desafio Diário.
class DailyStage {
  const DailyStage({
    required this.size,
    required this.nets,
    required this.winding,
    required this.slack,
    required this.bonus,
    required this.level,
  });

  final int size;
  final int nets;
  final double winding;
  final double slack;
  final int bonus;
  final int level;
}

const List<DailyStage> dailyStages = [
  DailyStage(size: 5, nets: 1, winding: 0.4, slack: 0.4, bonus: 0, level: 0),
  DailyStage(size: 6, nets: 1, winding: 0.6, slack: 0.3, bonus: 1, level: 1),
  DailyStage(size: 7, nets: 2, winding: 0.5, slack: 0.22, bonus: 2, level: 2),
];
