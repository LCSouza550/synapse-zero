import 'models.dart';

/// Estrelas (1 a 3) conforme o número de movimentos usados.
int starsFor(Level level, int moves) {
  if (moves <= level.optCW) return 3;
  if (moves <= level.optCW + (level.slack / 2).ceil()) return 2;
  return 1;
}

/// Pontuação de uma vitória. Com [assist], vale metade.
int scoreFor(Level level, int clicksLeft, int stars, {bool assist = false}) {
  final int remaining = clicksLeft < 0 ? 0 : clicksLeft;
  final int points = 100 + 40 * level.pathTiles + 10 * remaining + 100 * stars;
  return assist ? (points / 2).round() : points;
}