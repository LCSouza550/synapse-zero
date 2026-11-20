// Aritmética de 32 bits idêntica à do JavaScript (Math.imul, >>> 0, | 0).
//
// Premissa: o código roda na Dart VM / AOT (Android), onde int tem 64 bits.
// Em dart2js (web) a multiplicação de dois inteiros de 32 bits perderia
// precisão, por isso este pacote não é um alvo suportado para web.

int _u32(int x) => x & 0xFFFFFFFF;

int _i32(int x) {
  final v = x & 0xFFFFFFFF;
  return v >= 0x80000000 ? v - 0x100000000 : v;
}

int _imul(int a, int b) => _i32(_i32(a) * _i32(b));

/// Gerador pseudoaleatório determinístico (mulberry32).
///
/// A mesma semente produz sempre a mesma sequência, o que garante que o
/// Desafio Diário seja idêntico para todos os jogadores no mesmo dia.
class Mulberry32 {
  Mulberry32(int seed) : _a = seed & 0xFFFFFFFF;

  int _a;

  /// Próximo valor em [0, 1).
  double next() {
    _a = _i32(_a + 0x6d2b79f5);
    var t = _imul(_a ^ (_u32(_a) >> 15), 1 | _a);
    t = _i32((t + _imul(t ^ (_u32(t) >> 7), 61 | t)) ^ t);
    return _u32(t ^ (_u32(t) >> 14)) / 4294967296;
  }
}

/// Hash FNV-1a de 32 bits, usado para derivar a semente do Desafio Diário.
int hashString(String input) {
  var h = _i32(2166136261);
  for (final unit in input.codeUnits) {
    h = _i32(h ^ unit);
    h = _imul(h, 16777619);
  }
  return _u32(h);
}
