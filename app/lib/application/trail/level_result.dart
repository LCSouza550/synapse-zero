/// Resultado de um tabuleiro concluído com vitória.
class LevelResult {
  const LevelResult({required this.stars, required this.score})
      : assert(stars >= 1 && stars <= 3, 'vitória vale de 1 a 3 estrelas');

  final int stars;
  final int score;
}
