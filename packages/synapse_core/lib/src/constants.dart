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

/// Quantidade de níveis em cada setor da Trilha Neural.
const int levelsPerSector = 5;

/// Setor da Trilha Neural ([levelsPerSector] níveis cada).
class Sector {
  const Sector(this.id, this.name, this.size, this.nets);

  final String id;
  final String name;
  final int size;
  final int nets;
}

/// 12 setores. Os quatro primeiros são os do protótipo. Cada ciclo seguinte
/// repete os quatro formatos de tabuleiro já validados (5x5, 6x6, 7x7 com 2
/// redes e 8x8 com 2 redes), com percursos mais sinuosos e folga menor
/// (ver `trailSpec`).
const List<Sector> sectors = [
  Sector('cortex', 'Córtex Primário', 5, 1),
  Sector('ponte', 'Ponte Sináptica', 6, 1),
  Sector('nucleo', 'Núcleo Quântico', 7, 2),
  Sector('singularidade', 'Singularidade', 8, 2),
  Sector('cortex-profundo', 'Córtex Profundo', 5, 1),
  Sector('fenda-talamica', 'Fenda Talâmica', 6, 1),
  Sector('matriz-entrelacada', 'Matriz Entrelaçada', 7, 2),
  Sector('horizonte-eventos', 'Horizonte de Eventos', 8, 2),
  Sector('rede-fantasma', 'Rede Fantasma', 5, 1),
  Sector('vacuo-sinaptico', 'Vácuo Sináptico', 6, 1),
  Sector('nucleo-absoluto', 'Núcleo Absoluto', 7, 2),
  Sector('ponto-zero', 'Ponto Zero', 8, 2),
];

const List<String> levelNames = [
  'Primeiro Pulso', 'Sinapse Linear', 'Desvio Duplo', 'Nó Capacitor', 'Guardião Alfa',
  'Ponte Inicial', 'Axônio Curto', 'Fenda Sináptica', 'Eco Dendrítico', 'Guardião Beta',
  'Duas Frequências', 'Spin Cruzado', 'Emaranhado', 'Colapso de Onda', 'Guardião Gama',
  'Horizonte', 'Lente Gravitacional', 'Órbita Instável', 'Ponto de Não Retorno', 'Guardião Zero',
  'Reentrada', 'Eco Profundo', 'Camada Cinzenta', 'Pulso Retardado', 'Guardião Delta',
  'Relé Silencioso', 'Corrente Lateral', 'Limiar Dourado', 'Sinapse Espelhada', 'Guardião Épsilon',
  'Par Entrelaçado', 'Fase Oposta', 'Interferência', 'Superposição', 'Guardião Zeta',
  'Luz Curvada', 'Maré Gravitacional', 'Disco de Acreção', 'Singularidade Nua', 'Guardião Eta',
  'Sinal Fantasma', 'Memória Residual', 'Eco do Vazio', 'Latência Zero', 'Guardião Teta',
  'Silêncio Elétrico', 'Flutuação Quântica', 'Pulso Invertido', 'Ruptura de Fase', 'Guardião Iota',
  'Densidade Máxima', 'Fusão Neural', 'Cascata', 'Ressonância Total', 'Guardião Kappa',
  'Último Neurônio', 'Colapso Total', 'Estado Fundamental', 'Zero Absoluto', 'Guardião Ômega',
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
