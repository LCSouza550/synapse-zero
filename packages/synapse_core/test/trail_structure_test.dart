// Estrutura da Trilha Neural: 60 níveis em 12 setores.
import 'package:synapse_core/synapse_core.dart';
import 'package:test/test.dart';

void main() {
  group('estrutura da Trilha', () {
    test('60 níveis em 12 setores de 5', () {
      expect(trailLength, 60);
      expect(sectors.length, 12);
      expect(sectors.length * levelsPerSector, trailLength);
      expect(levelNames.length, trailLength);
    });

    test('nomes de níveis e de setores são únicos e não vazios', () {
      expect(levelNames.toSet().length, levelNames.length);
      expect(levelNames.every((n) => n.trim().isNotEmpty), isTrue);
      expect(sectors.map((s) => s.name).toSet().length, sectors.length);
      expect(sectors.map((s) => s.id).toSet().length, sectors.length);
    });

    test('chefe no último nível de cada setor, e só nele', () {
      for (var i = 0; i < trailLength; i++) {
        expect(
          trailSpec(i).boss,
          i % levelsPerSector == levelsPerSector - 1,
          reason: 'nível ${i + 1}',
        );
      }
    });

    test('o nome do nível e o tamanho do tabuleiro seguem o setor', () {
      for (var i = 0; i < trailLength; i++) {
        final sector = sectors[i ~/ levelsPerSector];
        final spec = trailSpec(i);
        expect(spec.name, levelNames[i], reason: 'nível ${i + 1}');
        expect(spec.size, sector.size, reason: 'nível ${i + 1}');
        expect(spec.nets, sector.nets, reason: 'nível ${i + 1}');
      }
    });

    test('sementes distintas em todos os níveis', () {
      final seeds = {for (var i = 0; i < trailLength; i++) trailSpec(i).seed};
      expect(seeds.length, trailLength);
    });

    test('parâmetros ficam dentro dos limites já validados', () {
      for (var i = 0; i < trailLength; i++) {
        final spec = trailSpec(i);
        expect(spec.winding, inInclusiveRange(0.15, 0.85), reason: 'nível ${i + 1}');
        expect(spec.slack, inInclusiveRange(0.1, 0.5), reason: 'nível ${i + 1}');
      }
    });

    test('Trilha: a partir do setor 5 a dificuldade não é menor que no setor equivalente', () {
      for (var i = 20; i < trailLength; i++) {
        final base = trailSpec(i - 20 * (i ~/ 20));
        final spec = trailSpec(i);
        expect(spec.winding, greaterThanOrEqualTo(base.winding), reason: 'nível ${i + 1}');
        expect(spec.slack, lessThanOrEqualTo(base.slack), reason: 'nível ${i + 1}');
      }
    });
  });
}
