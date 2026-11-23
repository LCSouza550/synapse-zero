import 'package:synapse_core/synapse_core.dart';

/// Estado de um nó no mapa da Trilha Neural.
enum TrailNodeState { done, current, locked }

/// Progresso do jogador na Trilha Neural (imutável).
///
/// Regras (as mesmas do protótipo): um nível concluído guarda o melhor
/// resultado e pode ser refeito; o próximo nível é o primeiro ainda sem
/// estrelas; os demais ficam bloqueados.
class TrailProgress {
  TrailProgress._(this._stars, this._scores);

  /// Nenhum nível concluído.
  factory TrailProgress.empty() => TrailProgress._(
        List<int>.filled(trailLength, 0),
        List<int>.filled(trailLength, 0),
      );

  /// Reconstrói o progresso a partir de listas salvas. Listas mais curtas
  /// (por exemplo, de quando a trilha tinha 20 níveis) são completadas com
  /// zeros; excedentes são descartados; estrelas ficam entre 0 e 3.
  factory TrailProgress.fromLists({
    required List<int> stars,
    List<int> scores = const [],
  }) {
    int bounded(int v, int max) => v < 0 ? 0 : (v > max ? max : v);
    return TrailProgress._(
      List<int>.generate(
        trailLength,
        (i) => i < stars.length ? bounded(stars[i], 3) : 0,
      ),
      List<int>.generate(
        trailLength,
        (i) => i < scores.length ? (scores[i] < 0 ? 0 : scores[i]) : 0,
      ),
    );
  }

  /// Total de estrelas possíveis na trilha.
  static const int maxStars = trailLength * 3;

  final List<int> _stars;
  final List<int> _scores;

  /// Estrelas (0 a 3) do nível [index]; 0 = ainda não concluído.
  int starsAt(int index) => _stars[index];

  /// Melhor pontuação do nível [index].
  int scoreAt(int index) => _scores[index];

  List<int> get stars => List.unmodifiable(_stars);
  List<int> get scores => List.unmodifiable(_scores);

  int get completedCount => _stars.where((s) => s > 0).length;
  int get totalStars => _stars.fold(0, (a, b) => a + b);
  int get totalPoints => _scores.fold(0, (a, b) => a + b);

  /// Primeiro nível ainda não concluído; `null` quando a trilha termina.
  int? get currentIndex {
    final i = _stars.indexWhere((s) => s == 0);
    return i < 0 ? null : i;
  }

  /// Nível mostrado no resumo: o atual ou, ao concluir tudo, o último.
  int get focusIndex => currentIndex ?? trailLength - 1;

  TrailNodeState stateOf(int index) {
    if (_stars[index] > 0) return TrailNodeState.done;
    return index == currentIndex ? TrailNodeState.current : TrailNodeState.locked;
  }

  bool canPlay(int index) => stateOf(index) != TrailNodeState.locked;

  /// Novo progresso com o resultado do nível [index]; mantém o melhor de
  /// estrelas e de pontuação.
  TrailProgress withResult(int index, {required int stars, required int score}) {
    assert(canPlay(index), 'nível bloqueado não pode receber resultado');
    final newStars = [..._stars];
    final newScores = [..._scores];
    final clamped = stars < 1 ? 1 : (stars > 3 ? 3 : stars);
    if (clamped > newStars[index]) newStars[index] = clamped;
    if (score > newScores[index]) newScores[index] = score;
    return TrailProgress._(newStars, newScores);
  }
}
