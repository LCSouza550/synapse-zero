import 'constants.dart';

/// Gira uma máscara de conexões [r] quartos de volta no sentido horário.
int rotMask(int mask, int r) {
  final turns = ((r % 4) + 4) % 4;
  var m = mask & 15;
  for (var k = 0; k < turns; k++) {
    m = ((m << 1) & 15) | (m >> 3);
  }
  return m;
}

/// Direção (0 a 3) da célula [a] para a célula vizinha [b] em uma grade
/// [n] x [n], ou -1 se não forem adjacentes.
int dirBetween(int n, int a, int b) {
  final deltaRow = (b ~/ n) - (a ~/ n);
  final deltaCol = (b % n) - (a % n);
  for (var d = 0; d < 4; d++) {
    if (dr[d] == deltaRow && dc[d] == deltaCol) return d;
  }
  return -1;
}
